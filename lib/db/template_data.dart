import 'app_database.dart';

class TemplateInUseException implements Exception {
  const TemplateInUseException();
}

/// Spec used when creating or updating a meso template — one entry per day.
class WorkoutDaySpec {
  const WorkoutDaySpec({
    required this.name,
    required this.isRestDay,
    required this.movementIds,
  });

  final String name;
  final bool isRestDay;
  final List<int> movementIds; // ordered
}

/// A single day within a loaded meso template, with its movements resolved.
class WorkoutDayData {
  const WorkoutDayData({required this.template, required this.movements});

  final WorkoutTemplate template;
  final List<Movement> movements; // ordered by exerciseIndex
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
