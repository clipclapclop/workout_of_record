import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'workout_cue_service.dart';

// ── Background task entry point ────────────────────────────────────────────────
// Must be a top-level function annotated with @pragma('vm:entry-point').

@pragma('vm:entry-point')
void _workoutTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

// ── Main-isolate service ───────────────────────────────────────────────────────

/// Manages the Android foreground service for workout tracking.
///
/// Responsibilities:
///   1. Shows a live-updating notification (exercise name + rest countdown).
///   2. Fires the rest-timer cue (TTS / haptic) when the countdown expires
///      while the app is backgrounded.
///
/// Double-cue prevention:
///   - The widget fires the cue and calls [notifyWidgetCued] → background skips.
///   - The background fires the cue and sends a message to main → [cuedByBackground]
///     is set, so the widget skips TTS but still calls markCued() on the controller.
class WorkoutForegroundService {
  WorkoutForegroundService._();

  /// True when the background task fired the cue while the app was in the
  /// background. The timer widget checks this to avoid double-speaking.
  static bool _cuedByBackground = false;
  static bool get cuedByBackground => _cuedByBackground;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Configure the foreground task options. Call once in main() before runApp.
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'workout_timer',
        channelName: 'Workout Timer',
        channelDescription: 'Shows exercise and rest-timer progress',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );
  }

  /// Register the callback that receives messages from the background task.
  /// Call once in main() after [FlutterForegroundTask.initCommunicationPort].
  static void initReceiver() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveData);
  }

  static void _onReceiveData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['type'] == 'cue') {
      _cuedByBackground = true;
      WorkoutCueService.fire(map['cueText'] as String?);
    }
  }

  /// Start the foreground service (shows the persistent notification).
  /// Safe to call if already running — checks first.
  static Future<void> start() async {
    final permission = await FlutterForegroundTask.requestNotificationPermission();
    if (permission == NotificationPermission.denied) return;

    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Workout in progress',
      notificationText: '',
      callback: _workoutTaskCallback,
    );
  }

  /// Stop the foreground service (removes the persistent notification).
  static Future<void> stop() async {
    _cuedByBackground = false;
    await FlutterForegroundTask.stopService();
  }

  // ── State updates (synchronous — sendDataToTask is sync) ───────────────────

  /// Push exercise name, cue text, and timer end time to the background task.
  /// [timerEndsAt] is null when the timer is not running.
  static void update({
    required String exerciseName,
    String? cueText,
    String? setInfo,
    DateTime? timerEndsAt,
  }) {
    FlutterForegroundTask.sendDataToTask({
      'type': 'update',
      'exerciseName': exerciseName,
      'cueText': cueText,
      'setInfo': setInfo,
      'timerEndsAtMs': timerEndsAt?.millisecondsSinceEpoch,
    });
  }

  /// Tell the background that there is no active timer (e.g., between exercises).
  static void clearTimer() {
    _cuedByBackground = false;
    FlutterForegroundTask.sendDataToTask({'type': 'clearTimer'});
  }

  /// Called by the widget after it fires the cue, so the background task skips.
  static void notifyWidgetCued() {
    FlutterForegroundTask.sendDataToTask({'type': 'widgetCued'});
  }

  /// Clear the "background cued" flag. Call whenever a new timer starts.
  static void clearCued() {
    _cuedByBackground = false;
  }
}

// ── Background task handler ────────────────────────────────────────────────────

class _WorkoutTaskHandler implements TaskHandler {
  String _exerciseName = '';
  String? _cueText;
  String? _setInfo;
  DateTime? _timerEndsAt;

  /// Set to true when the foreground widget fires the cue first, so we skip.
  bool _cuedByWidget = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final now = DateTime.now();
    final remaining = _timerEndsAt?.difference(now);
    final expired = remaining != null && remaining.isNegative;

    // Fire cue if timer just expired and the widget hasn't already done it.
    if (expired && !_cuedByWidget) {
      _timerEndsAt = null; // one-shot — prevent re-firing on subsequent ticks
      FlutterForegroundTask.sendDataToMain({'type': 'cue', 'cueText': _cueText});
    }

    // Build notification text.
    final String timerText;
    if (expired || (_timerEndsAt == null && _cuedByWidget)) {
      timerText = 'Ready!';
    } else if (_timerEndsAt != null && remaining != null) {
      final s = remaining.inSeconds.clamp(0, 5999);
      final m = s ~/ 60;
      final sec = s % 60;
      timerText =
          'Rest: ${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    } else {
      timerText = '';
    }
    final String notifText;
    if (_setInfo != null && timerText.isNotEmpty) {
      notifText = '$_setInfo  |  $timerText';
    } else if (_setInfo != null) {
      notifText = _setInfo!;
    } else {
      notifText = timerText;
    }

    await FlutterForegroundTask.updateService(
      notificationTitle:
          _exerciseName.isEmpty ? 'Workout in progress' : _exerciseName,
      notificationText: notifText,
    );
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  @override
  void onNotificationPressed() {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    switch (map['type'] as String?) {
      case 'update':
        _exerciseName = map['exerciseName'] as String? ?? '';
        _cueText = map['cueText'] as String?;
        _setInfo = map['setInfo'] as String?;
        final ms = map['timerEndsAtMs'] as int?;
        _timerEndsAt =
            ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
        _cuedByWidget = false;
      case 'clearTimer':
        _timerEndsAt = null;
        _cuedByWidget = false;
      case 'widgetCued':
        _cuedByWidget = true;
        _timerEndsAt = null;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
