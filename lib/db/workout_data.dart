import 'app_database.dart';

/// The in-progress attempt contains broken owned records that can be removed
/// safely without changing its planned workout or completed history.
class WorkoutDataIntegrityException implements Exception {
  const WorkoutDataIntegrityException.resettable() : canReset = true;
  const WorkoutDataIntegrityException.notResettable() : canReset = false;

  final bool canReset;
}

class ActiveWorkoutReference {
  const ActiveWorkoutReference({
    required this.completedWorkoutId,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.mesocycleId,
  });

  final int completedWorkoutId;
  final int workoutId;
  final String workoutName;
  final DateTime startedAt;
  final int mesocycleId;
}

class SetData {
  const SetData({required this.completed, this.planned});
  final CompletedSet completed;
  final PlannedSet? planned;
}

class ExerciseData {
  const ExerciseData({
    required this.completed,
    required this.movement,
    required this.sets,
    this.postExerciseCheckin,
  });
  final CompletedExercise completed;
  final Movement movement;
  final List<SetData> sets;
  final PostExerciseCheckin? postExerciseCheckin;
}

class WorkoutData {
  const WorkoutData({
    required this.completedWorkout,
    required this.workout,
    required this.exercises,
    required this.postMuscleGroupCheckins,
  });
  final CompletedWorkout completedWorkout;
  final Workout workout;
  final List<ExerciseData> exercises;
  final List<PostMuscleGroupCheckin> postMuscleGroupCheckins;

  static bool setIsDone(SetData s, Movement m) {
    final cs = s.completed;
    final repsOk = !m.isRequiredReps || cs.reps != null;
    final weightOk = !m.isRequiredWeight || cs.weight != null;
    final distanceOk = !m.isRequiredDistance || cs.distance != null;
    final timeOk = !m.isRequiredTime || cs.time != null;
    return (repsOk && weightOk && distanceOk && timeOk) ||
        cs.skipReason != null;
  }
}
