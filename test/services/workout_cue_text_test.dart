import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/workout_cue_text.dart';

void main() {
  group('buildWorkoutCueText', () {
    test('returns ready fallback when rightmost reps are not planned', () {
      final cue = buildWorkoutCueText(
        _movement(reps: true, weight: true),
        _plannedSet(weight: 80),
      );

      expect(cue, isNull);
    });

    test('speaks planned reps instead of an earlier weight field', () {
      final cue = buildWorkoutCueText(
        _movement(reps: true, weight: true),
        _plannedSet(reps: 10, weight: 80),
      );

      expect(cue, '10 reps');
    });

    test('returns ready fallback when rightmost time is not planned', () {
      final cue = buildWorkoutCueText(
        _movement(distance: true, time: true),
        _plannedSet(distance: 5),
      );

      expect(cue, isNull);
    });

    test('speaks the rightmost planned time field', () {
      final cue = buildWorkoutCueText(
        _movement(distance: true, time: true),
        _plannedSet(distance: 5, time: 45),
      );

      expect(cue, '45 seconds');
    });

    test('speaks weight in pounds', () {
      final cue = buildWorkoutCueText(
        _movement(weight: true),
        _plannedSet(weight: 82.5),
      );

      expect(cue, '82.5 pounds');
    });

    test('speaks distance in miles', () {
      final cue = buildWorkoutCueText(
        _movement(distance: true),
        _plannedSet(distance: 3.1),
      );

      expect(cue, '3.1 miles');
    });
  });
}

Movement _movement({
  bool reps = false,
  bool weight = false,
  bool time = false,
  bool distance = false,
}) => Movement(
  id: 1,
  name: 'Test movement',
  muscleGroup: MuscleGroup.other,
  isRequiredReps: reps,
  isRequiredWeight: weight,
  isRequiredTime: time,
  isRequiredDistance: distance,
  category: MovementCategory.resistance,
  bodyweightLoadFraction: 0,
);

PlannedSet _plannedSet({
  int? reps,
  double? weight,
  double? time,
  double? distance,
}) => PlannedSet(
  id: 1,
  plannedExerciseId: 1,
  reps: reps,
  weight: weight,
  time: time,
  distance: distance,
);
