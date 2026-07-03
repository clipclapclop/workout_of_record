import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/planning.dart';
import 'package:workout_of_record/db/tables/enums.dart';

Movement _movement({
  double minWeight = 0,
  double weightDelta = 5,
  double bodyweightLoadFraction = 0,
}) {
  return Movement(
    id: 1,
    name: 'Test movement',
    minWeight: minWeight,
    weightDelta: weightDelta,
    muscleGroup: MuscleGroup.quads,
    isRequiredReps: true,
    isRequiredWeight: true,
    isRequiredTime: false,
    isRequiredDistance: false,
    category: MovementCategory.resistance,
    bodyweightLoadFraction: bodyweightLoadFraction,
  );
}

CompletedSet _set(int id, {int reps = 10, double weight = 100}) =>
    CompletedSet(id: id, completedExerciseId: 1, reps: reps, weight: weight);

void main() {
  test('deload workouts front-load the rounded one-third heavy count', () {
    expect(List.generate(5, (i) => deloadTypeForWorkout(i, 5)), [
      DeloadType.heavy,
      DeloadType.heavy,
      DeloadType.easy,
      DeloadType.easy,
      DeloadType.easy,
    ]);
    expect(List.generate(4, (i) => deloadTypeForWorkout(i, 4)), [
      DeloadType.heavy,
      DeloadType.easy,
      DeloadType.easy,
      DeloadType.easy,
    ]);
  });

  test('progression-off deload copies the prior prescription', () {
    final prior = [_set(1, reps: 9, weight: 95), _set(2, reps: 8, weight: 90)];

    final result = computeHeuristic(
      prior,
      WeekGoal.deload,
      _movement(bodyweightLoadFraction: 0.85),
      prior.length,
      autoProgress: false,
      deloadType: DeloadType.easy,
      bodyWeight: 200,
    );

    expect(result.length, 2);
    expect(result.map((s) => s.reps), [9, 8]);
    expect(result.map((s) => s.weight), [95, 90]);
  });

  test('heavy deload reduces sets, reps, and effective load', () {
    final result = computeHeuristic(
      List.generate(5, (i) => _set(i)),
      WeekGoal.deload,
      _movement(bodyweightLoadFraction: 0.85),
      5,
      autoProgress: true,
      deloadType: DeloadType.heavy,
      bodyWeight: 200,
    );

    expect(result.length, 2); // round(5 * .40)
    expect(result.every((s) => s.reps == 5), isTrue);
    expect(result.every((s) => s.weight == 75), isTrue);
  });

  test('easy deload rounds reps and load to available increments', () {
    final result = computeHeuristic(
      List.generate(5, (i) => _set(i)),
      WeekGoal.deload,
      _movement(bodyweightLoadFraction: 0.5),
      5,
      autoProgress: true,
      deloadType: DeloadType.easy,
      bodyWeight: 100,
    );

    expect(result.length, 2); // round(5 * .30)
    expect(result.every((s) => s.reps == 7), isTrue);
    expect(result.every((s) => s.weight == 50), isTrue);
  });

  test('nearest increment may keep a light heavy-deload weight unchanged', () {
    final result = computeHeuristic(
      [_set(1, weight: 15)],
      WeekGoal.deload,
      _movement(minWeight: 5, weightDelta: 5),
      1,
      autoProgress: true,
      deloadType: DeloadType.heavy,
    );

    expect(result.single.weight, 15);
  });

  test('negative external load models assistance', () {
    final result = computeHeuristic(
      [_set(1, weight: -50)],
      WeekGoal.deload,
      _movement(minWeight: -200, weightDelta: 5, bodyweightLoadFraction: 1),
      1,
      autoProgress: true,
      deloadType: DeloadType.easy,
      bodyWeight: 175,
    );

    expect(result.single.weight, -95);
  });
}
