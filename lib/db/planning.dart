import 'dart:math';

import 'app_database.dart';
import 'tables/enums.dart';

class PlannedSetValues {
  final int? reps;
  final double? weight;
  final double? time;

  const PlannedSetValues({this.reps, this.weight, this.time});
}

/// Returns one [PlannedSetValues] per planned set to create.
///
/// [priorSets] must be pre-filtered to exclude skipped sets (skipReason == null).
/// Empty [priorSets] triggers cold start: 2 null sets.
///
/// Hard week: copy all prior sets as-is.
/// Deload week: ceil(2/3 * count) sets at 65% weight, rounded to movement increment.
List<PlannedSetValues> computeHeuristic(
  List<CompletedSet> priorSets,
  WeekGoal goal,
  Movement movement,
) {
  if (priorSets.isEmpty) {
    return [const PlannedSetValues(), const PlannedSetValues()];
  }

  switch (goal) {
    case WeekGoal.hard:
      return priorSets
          .map((s) => PlannedSetValues(reps: s.reps, weight: s.weight, time: s.time))
          .toList();

    case WeekGoal.deload:
      final count = (priorSets.length * 2 / 3).ceil();
      return priorSets.take(count).map((s) => PlannedSetValues(
            reps: s.reps,
            weight: _roundToMovementIncrement(
              s.weight != null ? s.weight! * 0.65 : null,
              movement,
            ),
            time: s.time,
          )).toList();
  }
}

double? _roundToMovementIncrement(double? rawWeight, Movement movement) {
  if (rawWeight == null) return null;
  final min = movement.minWeight ?? 0.0;
  final delta = movement.weightDelta;
  if (delta == null || delta <= 0) return rawWeight;
  final n = max(0, ((rawWeight - min) / delta).round());
  return min + n * delta;
}
