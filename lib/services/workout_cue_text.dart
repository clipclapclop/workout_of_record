import '../db/app_database.dart';
import '../workout_units.dart';

/// Builds the spoken rest-timer cue from the rightmost field shown for a set.
///
/// Returning null tells the cue service to say "ready". In particular, an
/// empty rightmost planned value must not fall back to an earlier field.
String? buildWorkoutCueText(
  Movement movement,
  PlannedSet plannedSet,
) {
  if (movement.isRequiredTime) {
    final time = plannedSet.time;
    return time == null ? null : '${_formatValue(time)} seconds';
  }
  if (movement.isRequiredDistance) {
    final distance = plannedSet.distance;
    if (distance == null) return null;
    return '${_formatValue(distance)} ${WorkoutUnits.spokenDistance}';
  }
  if (movement.isRequiredReps) {
    final reps = plannedSet.reps;
    return reps == null ? null : '$reps reps';
  }
  if (movement.isRequiredWeight) {
    final weight = plannedSet.weight;
    if (weight == null) return null;
    return '${_formatValue(weight)} ${WorkoutUnits.spokenWeight}';
  }
  return null;
}

String _formatValue(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();
