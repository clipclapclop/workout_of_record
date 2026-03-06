import 'app_database.dart';

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
    final timeOk = !m.isRequiredTime || cs.time != null;
    return (repsOk && weightOk && timeOk) || cs.skipReason != null;
  }
}
