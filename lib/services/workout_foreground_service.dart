import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../db/tables/enums.dart';
import 'workout_background_cue.dart';
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
///   - Once the foreground task is ready, it owns delivery and tells the widget
///     when the cue has fired.
///   - If the task is unavailable, the widget fires a UI fallback and calls
///     [notifyWidgetCued] so a late background tick skips the cue.
class WorkoutForegroundService {
  WorkoutForegroundService._();

  /// True when the background task fired the cue while the app was in the
  /// background. The timer widget checks this to avoid double-speaking.
  static bool _cuedByBackground = false;
  static bool _taskReady = false;

  static bool get cuedByBackground => _cuedByBackground;
  static bool get taskReady => _taskReady;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Configure the foreground task options. Call once in main() before runApp.
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'workout_timer_v2',
        channelName: 'Workout Timer',
        channelDescription: 'Shows exercise and rest-timer progress',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
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
    switch (map['type'] as String?) {
      case 'ready':
        _taskReady = true;
      case 'cue':
        _cuedByBackground = true;
      case 'cueFallback':
        _cuedByBackground = true;
        WorkoutCueService.fire(map['cueText'] as String?);
    }
  }

  /// Start the foreground service (shows the persistent notification).
  /// Safe to call if already running — checks first.
  static Future<bool> start() async {
    // Notification permission controls where Android 13+ displays the required
    // foreground-service notice; denial does not prohibit starting the service.
    try {
      await FlutterForegroundTask.requestNotificationPermission();
    } catch (_) {}

    if (!await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: 'Workout in progress',
        notificationText: '',
        callback: _workoutTaskCallback,
      );
      if (result is ServiceRequestFailure) return false;
    }

    // Starting the Android service and creating its Dart task are separate
    // asynchronous steps. Ping until the task confirms it can receive state,
    // preventing the first timer update from being dropped during startup.
    for (var attempt = 0; attempt < 30 && !_taskReady; attempt++) {
      FlutterForegroundTask.sendDataToTask({'type': 'ping'});
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return _taskReady;
  }

  /// Stop the foreground service (removes the persistent notification).
  static Future<void> stop() async {
    _cuedByBackground = false;
    _taskReady = false;
    await FlutterForegroundTask.stopService();
  }

  // ── State updates (synchronous — sendDataToTask is sync) ───────────────────

  /// Push exercise name, cue text, and timer end time to the background task.
  /// [timerEndsAt] is null when the timer is not running.
  static void update({
    required String exerciseName,
    String? cueText,
    String? setInfo,
    required TimerSound sound,
    required bool haptic,
    DateTime? timerEndsAt,
  }) {
    FlutterForegroundTask.sendDataToTask({
      'type': 'update',
      'exerciseName': exerciseName,
      'cueText': cueText,
      'setInfo': setInfo,
      'sound': sound.name,
      'haptic': haptic,
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
  final _state = WorkoutTimerTaskState();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    FlutterForegroundTask.sendDataToMain({'type': 'ready'});
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final tick = _state.tick(timestamp);
    if (tick.shouldCue) {
      final delivered = await WorkoutBackgroundCue.instance.fire(
        cueText: tick.cueText,
        sound: tick.sound,
        haptic: tick.haptic,
      );
      FlutterForegroundTask.sendDataToMain({
        'type': delivered ? 'cue' : 'cueFallback',
        'cueText': tick.cueText,
      });
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: tick.notificationTitle,
      notificationText: tick.notificationText,
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
    if (map['type'] == 'ping') {
      FlutterForegroundTask.sendDataToMain({'type': 'ready'});
      return;
    }
    _state.receive(map);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// Testable timer state owned by the foreground task isolate.
class WorkoutTimerTaskState {
  String _exerciseName = '';
  String? _cueText;
  String? _setInfo;
  TimerSound _sound = TimerSound.tts;
  bool _haptic = true;
  DateTime? _timerEndsAt;
  bool _cuedByWidget = false;
  bool _ready = false;

  void receive(Map<String, dynamic> map) {
    switch (map['type'] as String?) {
      case 'update':
        _exerciseName = map['exerciseName'] as String? ?? '';
        _cueText = map['cueText'] as String?;
        _setInfo = map['setInfo'] as String?;
        _sound = _parseSound(map['sound']);
        _haptic = map['haptic'] as bool? ?? true;
        final ms = map['timerEndsAtMs'] as int?;
        _timerEndsAt = ms == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ms);
        _cuedByWidget = false;
        _ready = false;
      case 'clearTimer':
        _timerEndsAt = null;
        _cuedByWidget = false;
        _ready = false;
      case 'widgetCued':
        _cuedByWidget = true;
        _timerEndsAt = null;
        _ready = true;
    }
  }

  WorkoutTimerTaskTick tick(DateTime now) {
    final remaining = _timerEndsAt?.difference(now);
    final expired = remaining != null && remaining.inMicroseconds <= 0;
    final shouldCue = expired && !_cuedByWidget;
    if (shouldCue) {
      _timerEndsAt = null;
      _ready = true;
    }

    final String timerText;
    if (_ready) {
      timerText = 'Ready!';
    } else if (_timerEndsAt != null && remaining != null) {
      final seconds = remaining.inSeconds.clamp(0, 5999);
      final minutes = seconds ~/ 60;
      final remainder = seconds % 60;
      timerText =
          'Rest: ${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
    } else {
      timerText = '';
    }

    final String notificationText;
    if (_setInfo != null && timerText.isNotEmpty) {
      notificationText = '$_setInfo  |  $timerText';
    } else if (_setInfo != null) {
      notificationText = _setInfo!;
    } else {
      notificationText = timerText;
    }

    return WorkoutTimerTaskTick(
      shouldCue: shouldCue,
      cueText: _cueText,
      sound: _sound,
      haptic: _haptic,
      notificationTitle: _exerciseName.isEmpty
          ? 'Workout in progress'
          : _exerciseName,
      notificationText: notificationText,
    );
  }

  TimerSound _parseSound(Object? value) {
    for (final sound in TimerSound.values) {
      if (sound.name == value) return sound;
    }
    return TimerSound.tts;
  }
}

class WorkoutTimerTaskTick {
  const WorkoutTimerTaskTick({
    required this.shouldCue,
    required this.cueText,
    required this.sound,
    required this.haptic,
    required this.notificationTitle,
    required this.notificationText,
  });

  final bool shouldCue;
  final String? cueText;
  final TimerSound sound;
  final bool haptic;
  final String notificationTitle;
  final String notificationText;
}
