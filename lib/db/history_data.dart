import 'app_database.dart';

class CompletedWorkoutSummary {
  const CompletedWorkoutSummary({
    required this.completedWorkout,
    required this.workoutName,
    required this.weekNumber,
    required this.mesoName,
    required this.mesocycleId,
  });

  final CompletedWorkout completedWorkout;
  final String workoutName;
  final int weekNumber;
  final String mesoName;
  final int mesocycleId;
}

class MovementHistoryEntry {
  const MovementHistoryEntry({
    required this.mesoId,
    required this.mesoName,
    required this.weekNumber,
    required this.workoutName,
    required this.workoutDate,
    required this.exercise,
    required this.sets,
  });

  final int mesoId;
  final String mesoName;
  final int weekNumber;
  final String workoutName;
  final DateTime workoutDate;
  final CompletedExercise exercise;
  final List<CompletedSet> sets;
}
