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
/// [targetCount] is the total number of sets from the prior week (including skipped),
/// so that skipped sets don't reduce next week's planned volume.
/// Zero [targetCount] triggers cold start: 2 null sets.
///
/// [autoProgress] controls whether the built-in progression algorithm is applied.
/// When true + hard week: +1 rep per set (only when reps are present).
/// When false: copy last week's values exactly (user-controlled).
///
/// Deload week: ceil(2/3 * targetCount) sets at 65% weight, same reps (no progression).
List<PlannedSetValues> computeHeuristic(
  List<CompletedSet> priorSets,
  WeekGoal goal,
  Movement movement,
  int targetCount, {
  bool autoProgress = false,
}) {
  if (targetCount == 0) {
    return [const PlannedSetValues(), const PlannedSetValues()];
  }

  switch (goal) {
    case WeekGoal.hard:
      return List.generate(
        targetCount,
        (i) => i < priorSets.length
            ? PlannedSetValues(
                reps: autoProgress && priorSets[i].reps != null
                    ? priorSets[i].reps! + 1
                    : priorSets[i].reps,
                weight: priorSets[i].weight,
                time: priorSets[i].time,
              )
            : const PlannedSetValues(),
      );

    case WeekGoal.deload:
      final count = (targetCount * 2 / 3).ceil();
      return List.generate(
        count,
        (i) => i < priorSets.length
            ? PlannedSetValues(
                reps: priorSets[i].reps,
                weight: _roundToMovementIncrement(
                  priorSets[i].weight != null ? priorSets[i].weight! * 0.65 : null,
                  movement,
                ),
                time: priorSets[i].time,
              )
            : const PlannedSetValues(),
      );
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
