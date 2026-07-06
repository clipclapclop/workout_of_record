import 'app_database.dart';

class TemplateInUseException implements Exception {
  const TemplateInUseException();
}

/// Per-exercise spec within a [WorkoutDaySpec] — carries movement ID and the
/// auto-progress flag so templates persist the setting across weeks.
class ExerciseSpec {
  const ExerciseSpec({required this.movementId, this.autoProgress = true});
  final int movementId;
  final bool autoProgress;
}

/// Spec used when creating or updating a meso template — one entry per day.
class WorkoutDaySpec {
  const WorkoutDaySpec({
    required this.name,
    required this.isRestDay,
    required this.exercises,
  });

  final String name;
  final bool isRestDay;
  final List<ExerciseSpec> exercises; // ordered
}

/// One exercise entry within a loaded [WorkoutDayData] — movement + AI flag.
class ExerciseDayEntry {
  const ExerciseDayEntry({required this.movement, required this.autoProgress});
  final Movement movement;
  final bool autoProgress;
}

/// A single day within a loaded meso template, with its exercises resolved.
class WorkoutDayData {
  const WorkoutDayData({required this.template, required this.exercises});

  final WorkoutTemplate template;
  final List<ExerciseDayEntry> exercises; // ordered by exerciseIndex
}

/// A fully loaded meso template — template row + its ordered days + movements.
class MesoTemplateData {
  const MesoTemplateData({required this.template, required this.days});

  final MesoTemplate template;
  final List<WorkoutDayData> days; // ordered by dayIndex
}

/// A completed historical week together with the saved template associated
/// with the mesocycle it came from.
class PastWeekTemplateData {
  const PastWeekTemplateData({
    required this.mesocycle,
    required this.week,
    required this.weekData,
    required this.associatedTemplate,
  });

  final Mesocycle mesocycle;
  final Week week;
  final MesoTemplateData weekData;
  final MesoTemplateData associatedTemplate;

  String get suggestedName =>
      'From ${mesocycle.name} W${week.weekNumber}';
}

List<WorkoutDaySpec> workoutDaySpecsFromData(MesoTemplateData data) => data.days
    .map((day) => WorkoutDaySpec(
          name: day.template.name,
          isRestDay: day.template.isRestDay,
          exercises: day.exercises
              .map((exercise) => ExerciseSpec(
                    movementId: exercise.movement.id,
                    autoProgress: exercise.autoProgress,
                  ))
              .toList(),
        ))
    .toList();

/// Summary of a single week within a mesocycle — used by the past-meso picker.
class WeekSummary {
  const WeekSummary({
    required this.week,
    required this.completedWorkoutCount,
    required this.totalWorkoutCount,
  });

  final Week week;
  final int completedWorkoutCount;
  final int totalWorkoutCount; // non-rest workouts in the week
}

/// A mesocycle with its weeks that have at least one completed workout.
class MesocycleWeekSummary {
  const MesocycleWeekSummary({
    required this.mesocycle,
    required this.weeks,
  });

  final Mesocycle mesocycle;
  final List<WeekSummary> weeks;
}

/// A meso template with its history of mesocycles that used it.
class MesoTemplateWithHistory {
  const MesoTemplateWithHistory({
    required this.template,
    required this.pastMesos,
  });

  final MesoTemplate template;
  final List<Mesocycle> pastMesos; // ordered by createdAt desc
}
