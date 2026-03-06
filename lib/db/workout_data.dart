import 'app_database.dart';

class SetData {
  const SetData({required this.completed, this.planned});
  final CompletedSet completed;
  final PlannedSet? planned; // null for user-added sets
}

class ExerciseData {
  const ExerciseData({
    required this.completed,
    required this.movement,
    required this.sets,
  });
  final CompletedExercise completed;
  final Movement movement;
  final List<SetData> sets;
}

class WorkoutData {
  const WorkoutData({
    required this.completedWorkout,
    required this.workout,
    required this.exercises,
  });
  final CompletedWorkout completedWorkout;
  final Workout workout;
  final List<ExerciseData> exercises;

  bool get isFinishable => exercises.every(
        (e) => e.sets.every((s) => setIsDone(s, e.movement)),
      );

  static bool setIsDone(SetData s, Movement m) {
    final cs = s.completed;
    final repsOk = !m.isRequiredReps || cs.reps != null;
    final weightOk = !m.isRequiredWeight || cs.weight != null;
    final timeOk = !m.isRequiredTime || cs.time != null;
    return (repsOk && weightOk && timeOk) || cs.skipReason != null;
  }
}
