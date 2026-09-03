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
  if (saved == null ||
      saved.workoutId != workoutId ||
      !saved.endsAt.isAfter(checkedAt)) {
    return false;
  }
  controller.restoreRunningTimer(
    durationSeconds: saved.durationSeconds,
    endsAt: saved.endsAt,
  );
  return true;
}
