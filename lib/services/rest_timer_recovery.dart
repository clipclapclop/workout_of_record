import '../app_preferences.dart';
import '../widgets/rest_timer_controller.dart';

/// Restore [controller] only when [saved] is a live timer for this workout.
bool restorePersistedRestTimer({
  required RestTimerController controller,
  required ActiveRestTimerState? saved,
  required int workoutId,
  DateTime? now,
}) {
  final checkedAt = now ?? DateTime.now();
  if (saved == null || saved.workoutId != workoutId) return false;
  final endsAt = saved.endsAt;
  if (endsAt == null) {
    controller.restorePausedTimer(
      durationSeconds: saved.durationSeconds,
      remainingMs: saved.remainingMs,
    );
    return true;
  }
  if (!endsAt.isAfter(checkedAt)) return false;
  controller.restoreRunningTimer(
    durationSeconds: saved.durationSeconds,
    endsAt: endsAt,
  );
  return true;
}
