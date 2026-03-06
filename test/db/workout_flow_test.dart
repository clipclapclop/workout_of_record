import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';

AppDatabase _openDb() =>
    AppDatabase.withExecutor(NativeDatabase.memory());

/// Returns the workout with [name] from week 1.
Future<Workout> _workoutByName(AppDatabase db, String name) =>
    (db.select(db.workouts)..where((w) => w.name.equals(name))).getSingle();

/// Inserts a completed_workout row for [workout] with the given date.
Future<void> _completeWorkout(
    AppDatabase db, Workout workout, DateTime date) async {
  final ts = DateTime(date.year, date.month, date.day, 12);
  await db.into(db.completedWorkouts).insert(
        CompletedWorkoutsCompanion.insert(
          workoutId: workout.id,
          startedAt: ts,
          completedAt: Value(ts),
          status: WorkoutStatus.completed,
        ),
      );
}

void main() {
  // Each test creates its own in-memory DB seeded by _seedData() via onCreate.

  test('1. getNextWorkout returns Day 1 on fresh DB', () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    final next = await db.getNextWorkout(mesocycleId);
    expect(next, isNotNull);
    expect(next!.name, 'Day 1');
    expect(next.isRestDay, false);
  });

  test('2. advanceRestDays is a no-op when no workouts are completed', () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    await db.advanceRestDays(mesocycleId);

    final count = await db.select(db.completedWorkouts).get();
    expect(count, isEmpty);
  });

  test(
      '3. advanceRestDays squishes Day 2 rest day when today == Day 1 date',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    final day1 = await _workoutByName(db, 'Day 1');
    final day1Date = DateTime(2025, 6, 10);
    await _completeWorkout(db, day1, day1Date);

    // today == day1Date → candidate (day1Date+1) is NOT before today → squish
    await db.advanceRestDays(mesocycleId, now: day1Date);

    final completed = await db.select(db.completedWorkouts).get();
    // Day 1 (manually inserted) + Day 2 (squished rest day)
    expect(completed.length, 2);

    final day2Row = completed.firstWhere((r) => r.workoutId != day1.id);
    final day2Date = day2Row.completedAt!;
    expect(DateTime(day2Date.year, day2Date.month, day2Date.day),
        DateTime(day1Date.year, day1Date.month, day1Date.day));
  });

  test(
      '4. advanceRestDays advances Day 2 rest day when today is 1 day after Day 1',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    final day1 = await _workoutByName(db, 'Day 1');
    final day1Date = DateTime(2025, 6, 10);
    await _completeWorkout(db, day1, day1Date);

    final today = day1Date.add(const Duration(days: 1)); // 2025-06-11
    await db.advanceRestDays(mesocycleId, now: today);

    final completed = await db.select(db.completedWorkouts).get();
    expect(completed.length, 2);

    final day2Row = completed.firstWhere((r) => r.workoutId != day1.id);
    final day2Date = day2Row.completedAt!;
    expect(DateTime(day2Date.year, day2Date.month, day2Date.day), today);
  });

  test(
      '5. advanceRestDays squishes Days 4 and 5 when today == Day 3 date',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    final day1 = await _workoutByName(db, 'Day 1');
    final day2 = await _workoutByName(db, 'Day 2');
    final day3 = await _workoutByName(db, 'Day 3');
    final baseDate = DateTime(2025, 6, 10);
    await _completeWorkout(db, day1, baseDate);
    await _completeWorkout(db, day2, baseDate); // rest day already done
    await _completeWorkout(db, day3, baseDate.add(const Duration(days: 2)));

    final day3Date = baseDate.add(const Duration(days: 2)); // 2025-06-12
    // today == day3Date → both Days 4+5 squish to day3Date
    await db.advanceRestDays(mesocycleId, now: day3Date);

    final completed = await db.select(db.completedWorkouts).get();
    // day1 + day2 + day3 (manual) + day4 + day5 (squished)
    expect(completed.length, 5);

    final day4 = await _workoutByName(db, 'Day 4');
    final day5 = await _workoutByName(db, 'Day 5');

    final day4Row = completed.firstWhere((r) => r.workoutId == day4.id);
    final day5Row = completed.firstWhere((r) => r.workoutId == day5.id);

    for (final row in [day4Row, day5Row]) {
      final d = row.completedAt!;
      expect(DateTime(d.year, d.month, d.day), day3Date);
    }
  });

  test('6. initializeWorkout creates correct completed rows', () async {
    final db = _openDb();
    addTearDown(db.close);

    final day1 = await _workoutByName(db, 'Day 1');
    final completedWorkoutId = await db.initializeWorkout(day1.id);

    final cwRows = await db.select(db.completedWorkouts).get();
    expect(cwRows.length, 1);
    expect(cwRows.first.id, completedWorkoutId);
    expect(cwRows.first.status, WorkoutStatus.active);
    expect(cwRows.first.completedAt, isNull);

    final ceRows = await (db.select(db.completedExercises)
          ..where((e) => e.completedWorkoutId.equals(completedWorkoutId)))
        .get();
    expect(ceRows.length, 3);

    // Verify orderIndex values are 0, 1, 2
    final indices = ceRows.map((e) => e.orderIndex).toList()..sort();
    expect(indices, [0, 1, 2]);

    int totalSets = 0;
    for (final ce in ceRows) {
      final sets = await (db.select(db.completedSets)
            ..where((s) => s.completedExerciseId.equals(ce.id)))
          .get();
      totalSets += sets.length;
      for (final s in sets) {
        expect(s.reps, isNull);
        expect(s.weight, isNull);
        expect(s.time, isNull);
      }
    }
    // Cable Fly(2) + Dumbbell Press(3) + Cable Tri(1) = 6
    expect(totalSets, 6);
  });

  test('7. savePreWorkoutCheckin inserts correct row', () async {
    final db = _openDb();
    addTearDown(db.close);

    final day1 = await _workoutByName(db, 'Day 1');
    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: day1.id,
      quads: const Value(Soreness.some),
      hamstrings: const Value(Soreness.none),
      abs: const Value(Soreness.none),
      chest: const Value(Soreness.aLittle),
      back: const Value(Soreness.none),
      biceps: const Value(Soreness.none),
      triceps: const Value(Soreness.none),
      traps: const Value(Soreness.none),
      forearms: const Value(Soreness.none),
      glutes: const Value(Soreness.none),
      calves: const Value(Soreness.none),
      shoulders: const Value(Soreness.none),
      sleepQuality: const Value(CurrentState.good),
      vimVigor: const Value(CurrentState.great),
      mentalState: const Value(CurrentState.great),
    ));

    final rows = await db.select(db.preWorkoutCheckins).get();
    expect(rows.length, 1);
    expect(rows.first.workoutId, day1.id);
    expect(rows.first.quads, Soreness.some);
    expect(rows.first.chest, Soreness.aLittle);
    expect(rows.first.sleepQuality, CurrentState.good);
  });

  test('8. Full flow: advanceRestDays + initializeWorkout + savePreWorkoutCheckin',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final appState = await db.getAppState();
    final mesocycleId = appState.currentMesocycleId!;

    // No prior workouts — advanceRestDays is a no-op.
    await db.advanceRestDays(mesocycleId);

    // Next workout is Day 1.
    final next = await db.getNextWorkout(mesocycleId);
    expect(next!.name, 'Day 1');

    // Save check-in.
    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: next.id,
    ));

    // Initialize workout.
    final completedWorkoutId = await db.initializeWorkout(next.id);

    // Verify final DB state.
    final checkins = await db.select(db.preWorkoutCheckins).get();
    expect(checkins.length, 1);
    expect(checkins.first.workoutId, next.id);

    final cw = await (db.select(db.completedWorkouts)
          ..where((w) => w.id.equals(completedWorkoutId)))
        .getSingle();
    expect(cw.status, WorkoutStatus.active);
    expect(cw.completedAt, isNull);

    final exercises = await (db.select(db.completedExercises)
          ..where((e) => e.completedWorkoutId.equals(completedWorkoutId)))
        .get();
    expect(exercises.length, 3);

    final allSets = await db.select(db.completedSets).get();
    expect(allSets.length, 6);
    expect(allSets.every((s) => s.reps == null && s.weight == null), true);
  });
}
