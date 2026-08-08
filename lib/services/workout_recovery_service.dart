import '../app_preferences.dart';
import '../db/app_database.dart';

/// Reconciles navigation acceleration pointers with persisted workout state.
///
/// The database is authoritative: an active workout can be recovered even if
/// the app closed before SharedPreferences was updated, while stale pointers
/// are removed after a workout or mesocycle finishes.
class WorkoutRecoveryService {
  const WorkoutRecoveryService._();

  static Future<void> reconcileNavigationPointers(AppDatabase database) async {
    final active = await database.getActiveWorkoutReference();
    if (active != null) {
      if (AppPreferences.getCurrentCompletedWorkoutId() !=
          active.completedWorkoutId) {
        await AppPreferences.setCurrentCompletedWorkoutId(
          active.completedWorkoutId,
        );
      }
      if (AppPreferences.getCurrentMesocycleId() != active.mesocycleId) {
        await AppPreferences.setCurrentMesocycleId(active.mesocycleId);
      }
      return;
    }

    if (AppPreferences.getCurrentCompletedWorkoutId() != null) {
      await AppPreferences.setCurrentCompletedWorkoutId(null);
    }

    final mesocycleId = AppPreferences.getCurrentMesocycleId();
    if (mesocycleId == null) return;
    final mesocycle = await (database.select(
      database.mesocycles,
    )..where((row) => row.id.equals(mesocycleId))).getSingleOrNull();
    if (mesocycle == null || mesocycle.completedAt != null) {
      await AppPreferences.setCurrentMesocycleId(null);
    }
  }
}
