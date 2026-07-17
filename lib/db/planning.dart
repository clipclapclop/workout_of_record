import 'dart:math';

import 'app_database.dart';
import 'tables/enums.dart';

class PlannedSetValues {
  final int? reps;
  final double? weight;
  final double? time;

  const PlannedSetValues({this.reps, this.weight, this.time});
}

enum DeloadType { heavy, easy }

/// Assigns the front-loaded deload type for a zero-based training-day index.
DeloadType deloadTypeForWorkout(int workoutIndex, int workoutCount) {
  final heavyCount = max(1, (workoutCount / 3).round());
  return workoutIndex < heavyCount ? DeloadType.heavy : DeloadType.easy;
}

/// Returns one [PlannedSetValues] per planned set to create.
///
/// [priorSets] must be pre-filtered to exclude skipped sets (skipReason == null).
/// [targetCount] is the total number of sets from the prior week (including skipped),
/// so that skipped sets don't reduce next week's planned volume.
/// Zero [targetCount] triggers cold start: 2 null sets.
///
/// [autoProgress] controls whether the built-in progression algorithm is applied.
/// When true + hard week: +1 rep per set (only when reps are present), and use
/// the final performed set's weight for every set.
/// When false: retain last week's values (user-controlled), while ensuring a
/// deload weight is valid for the movement's configured equipment.
///
/// [addExtraSet] (hard week + autoProgress only): when true, appends one extra
/// planned set with the carried-forward weight and null reps. Caller decides
/// which exercises qualify based on the week/muscle-group alternation rule.
///
/// Exercises with progression disabled retain their prior prescription, with
/// deload weights snapped to the movement's available equipment increments.
/// Progressing deload exercises use the supplied front-loaded [deloadType].
List<PlannedSetValues> computeHeuristic(
  List<CompletedSet> priorSets,
  WeekGoal goal,
  Movement movement,
  int targetCount, {
  bool autoProgress = false,
  bool addExtraSet = false,
  DeloadType deloadType = DeloadType.easy,
  double? bodyWeight,
}) {
  if (targetCount == 0) {
    return [const PlannedSetValues(), const PlannedSetValues()];
  }

  switch (goal) {
    case WeekGoal.hard:
      final extra = autoProgress && addExtraSet;
      final count = extra ? targetCount + 1 : targetCount;
      final progressionWeight = autoProgress
          ? priorSets.lastOrNull?.weight
          : null;
      return List.generate(count, (i) {
        if (i < priorSets.length) {
          final priorSet = priorSets[i];
          return PlannedSetValues(
            reps: autoProgress && priorSet.reps != null
                ? priorSet.reps! + 1
                : priorSet.reps,
            weight: autoProgress ? progressionWeight : priorSet.weight,
            time: priorSet.time,
          );
        }
        return PlannedSetValues(weight: progressionWeight);
      });

    case WeekGoal.deload:
      if (!autoProgress) {
        return _copyPriorSets(priorSets, targetCount, movement);
      }
      final setMultiplier = deloadType == DeloadType.heavy ? 0.40 : 0.30;
      final repMultiplier = deloadType == DeloadType.heavy ? 0.50 : 0.65;
      final loadMultiplier = deloadType == DeloadType.heavy ? 0.90 : 0.65;
      final count = max(1, (targetCount * setMultiplier).round());
      final firstPriorReps = priorSets.firstOrNull?.reps;
      final deloadReps = firstPriorReps == null
          ? null
          : max(1, (firstPriorReps * repMultiplier).round());
      return List.generate(
        count,
        (i) => i < priorSets.length
            ? PlannedSetValues(
                reps: deloadReps,
                weight: _roundToMovementIncrement(
                  _deloadExternalWeight(
                    priorSets[i].weight,
                    loadMultiplier,
                    movement.bodyweightLoadFraction,
                    bodyWeight,
                  ),
                  movement,
                ),
                time: priorSets[i].time,
              )
            : PlannedSetValues(reps: deloadReps),
      );
  }
}

List<PlannedSetValues> _copyPriorSets(
  List<CompletedSet> priorSets,
  int targetCount,
  Movement movement,
) {
  return List.generate(
    targetCount,
    (i) => i < priorSets.length
        ? PlannedSetValues(
            reps: priorSets[i].reps,
            weight: _roundToMovementIncrement(priorSets[i].weight, movement),
            time: priorSets[i].time,
          )
        : const PlannedSetValues(),
  );
}

double? _deloadExternalWeight(
  double? externalWeight,
  double loadMultiplier,
  double bodyweightLoadFraction,
  double? bodyWeight,
) {
  if (externalWeight == null) return null;
  if (bodyWeight == null || bodyweightLoadFraction == 0) {
    return externalWeight * loadMultiplier;
  }
  final bodyweightLoad = bodyWeight * bodyweightLoadFraction;
  final effectiveLoad = externalWeight + bodyweightLoad;
  return effectiveLoad * loadMultiplier - bodyweightLoad;
}

double? _roundToMovementIncrement(double? rawWeight, Movement movement) {
  if (rawWeight == null) return null;
  final min = movement.minWeight ?? 0.0;
  final delta = movement.weightDelta;
  if (delta == null || delta <= 0) return rawWeight;
  final n = max(0, ((rawWeight - min) / delta).round());
  return min + n * delta;
}
