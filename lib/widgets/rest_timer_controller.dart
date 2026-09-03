import 'dart:math';

import 'package:flutter/foundation.dart';

/// Manages countdown state for the rest timer.
///
/// Uses wall-clock timestamps so the countdown survives app
/// backgrounding/foregrounding correctly.
class RestTimerController extends ChangeNotifier {
  RestTimerController({required int durationSeconds})
    : _durationSeconds = durationSeconds,
      _pausedRemainingMs = durationSeconds * 1000;

  int _durationSeconds;
  int _pausedRemainingMs;
  DateTime? _startedAt;
  bool _cued = false; // whether the zero-cue has already fired this round

  // ── Getters ────────────────────────────────────────────────────────────────

  int get durationSeconds => _durationSeconds;
  bool get isRunning => _startedAt != null;
  bool get cued => _cued;

  /// Milliseconds remaining.  Clamped to [0, durationSeconds * 1000].
  int get remainingMs {
    if (_startedAt == null) return _pausedRemainingMs;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    return max(0, _durationSeconds * 1000 - elapsed);
  }

  // ── Control ────────────────────────────────────────────────────────────────

  /// Start (or restart from zero if the timer has already expired).
  void start() {
    int startFrom = _pausedRemainingMs;
    if (startFrom <= 0) {
      // Already at zero — restart from the full duration.
      startFrom = _durationSeconds * 1000;
      _cued = false;
    }
    // Backdate _startedAt so that remaining == startFrom immediately.
    _startedAt = DateTime.now().subtract(
      Duration(milliseconds: _durationSeconds * 1000 - startFrom),
    );
    notifyListeners();
  }

  /// Pause the countdown and preserve both its remaining time and set context.
  void stop() {
    _pausedRemainingMs = remainingMs;
    _startedAt = null;
    notifyListeners();
  }

  /// Reset to the full duration and stop.
  void reset() {
    _startedAt = null;
    _pausedRemainingMs = _durationSeconds * 1000;
    _cued = false;
    notifyListeners();
  }

  /// Update the duration and reset.
  void setDuration(int seconds) {
    _durationSeconds = seconds;
    reset(); // reset() already calls notifyListeners
  }

  /// Restore a persisted paused timer without starting it.
  void restorePausedTimer({
    required int durationSeconds,
    required int remainingMs,
  }) {
    _durationSeconds = durationSeconds;
    _pausedRemainingMs = remainingMs.clamp(0, durationSeconds * 1000).toInt();
    _startedAt = null;
    _cued = _pausedRemainingMs <= 0;
    notifyListeners();
  }

  /// Restore a persisted countdown without giving it a new deadline.
  void restoreRunningTimer({
    required int durationSeconds,
    required DateTime endsAt,
  }) {
    _durationSeconds = durationSeconds;
    final fullDurationMs = durationSeconds * 1000;
    final now = DateTime.now();
    final restoredRemainingMs = endsAt
        .difference(now)
        .inMilliseconds
        .clamp(0, fullDurationMs)
        .toInt();
    _pausedRemainingMs = restoredRemainingMs;
    _cued = restoredRemainingMs <= 0;
    _startedAt = restoredRemainingMs <= 0
        ? null
        : now.subtract(
            Duration(milliseconds: fullDurationMs - restoredRemainingMs),
          );
    notifyListeners();
  }

  /// Called by the widget after it has fired the cue so we don't fire twice.
  void markCued() {
    // Stop the active countdown at zero before recording cue delivery.
    _pausedRemainingMs = 0;
    _startedAt = null;
    _cued = true;
    notifyListeners();
  }
}

/// Whether [interactedSetId] is the final usable set in workout order.
bool isFinalUsableWorkoutSet({
  required int interactedSetId,
  required Iterable<int> orderedSetIds,
  Set<int> excludedSetIds = const {},
}) {
  int? finalUsableSetId;
  for (final setId in orderedSetIds) {
    if (!excludedSetIds.contains(setId)) finalUsableSetId = setId;
  }
  return finalUsableSetId == interactedSetId;
}
