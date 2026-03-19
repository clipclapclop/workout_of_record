import 'app_database.dart';

class TemplateInUseException implements Exception {
  const TemplateInUseException();
}

/// Per-exercise spec within a [WorkoutDaySpec] — carries movement ID and the
/// AI-control flag so templates persist the setting across weeks.
class ExerciseSpec {
  const ExerciseSpec({required this.movementId, this.aiPlanned = true});
  final int movementId;
  final bool aiPlanned;
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
  const ExerciseDayEntry({required this.movement, required this.aiPlanned});
  final Movement movement;
  final bool aiPlanned;
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

/// A meso template with its history of mesocycles that used it.
class MesoTemplateWithHistory {
  const MesoTemplateWithHistory({
    required this.template,
    required this.pastMesos,
  });

  final MesoTemplate template;
  final List<Mesocycle> pastMesos; // ordered by createdAt desc
}
