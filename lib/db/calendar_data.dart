import 'app_database.dart';
import 'tables/enums.dart';

class CalendarCell {
  const CalendarCell({
    required this.workoutName,
    required this.orderIndex,
    this.workoutId,
    this.completedWorkout,
    this.workoutTemplateId,
  });
  final String workoutName;
  final int orderIndex;
  // Set for materialized workouts (weeks already in DB).
  final int? workoutId;
  final CompletedWorkout? completedWorkout;
  // Set for template-only cells (future weeks not yet materialized).
  final int? workoutTemplateId;
}

class CalendarWeek {
  const CalendarWeek({
    required this.weekNumber,
    required this.goal,
    required this.cells,
  });
  final int weekNumber;
  final WeekGoal goal;
  final List<CalendarCell> cells;
}

class MesocycleCalendar {
  const MesocycleCalendar({
    required this.mesoName,
    required this.totalWeekCount,
    required this.weeks,
  });
  final String mesoName;
  final int totalWeekCount;
  final List<CalendarWeek> weeks;
}

class PlannedExerciseEntry {
  const PlannedExerciseEntry({
    required this.movementName,
    required this.setCount,
  });
  final String movementName;
  final int setCount;
}
