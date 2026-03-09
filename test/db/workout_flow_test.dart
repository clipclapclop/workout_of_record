import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';

AppDatabase _openDb() =>
    AppDatabase.withExecutor(NativeDatabase.memory());

/// Creates a mesocycle from the seeded default template.
Future<int> _createMeso(AppDatabase db, {int totalWeeks = 2}) async {
  final templates = await db.getMesoTemplates();
  return db.createMesocycle(templates.first.id, 'Test Meso', totalWeeks);
}

/// Generates planned data, initializes, then finishes a workout.
Future<void> _completeWorkoutFull(AppDatabase db, int workoutId) async {
  await db.generatePlannedWorkout(workoutId);
  final cwId = await db.initializeWorkout(workoutId);
  await db.finishWorkout(cwId);
}

void main() {
  // Each test creates its own in-memory DB seeded by _seedData() via onCreate.
  // Seed data: movements + default template (Day1/rest/Day3/rest/rest), no mesocycle.

  test('1. Fresh meso: getOrCreateNextWorkout creates week 1 and returns Day 1',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final next = await db.getOrCreateNextWorkout(mesoId);

    expect(next, isNotNull);
    expect(next!.name, 'Day 1');
    expect(next.isRestDay, false);

    // Week 1 should now exist.
    final weekRows = await db.select(db.weeks).get();
    expect(weekRows.length, 1);
    expect(weekRows.first.weekNumber, 1);
    expect(weekRows.first.goal, WeekGoal.hard); // totalWeeks=2, week 1 is hard

    // Exactly one workout row created (only Day 1, lazily).
    final workoutRows = await db.select(db.workouts).get();
    expect(workoutRows.length, 1);
  });

  test('2. getOrCreateNextWorkout is idempotent before workout starts', () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final first = await db.getOrCreateNextWorkout(mesoId);
    final second = await db.getOrCreateNextWorkout(mesoId);

    expect(first!.id, second!.id);
    // Still only one workout row.
    final workoutRows = await db.select(db.workouts).get();
    expect(workoutRows.length, 1);
  });

  test('3. generatePlannedWorkout creates 2 planned exercises and 4 sets for Day 1',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final workout = await db.getOrCreateNextWorkout(mesoId);

    await db.generatePlannedWorkout(workout!.id);

    final pwRows = await db.select(db.plannedWorkouts).get();
    expect(pwRows.length, 1);

    final peRows = await db.select(db.plannedExercises).get();
    expect(peRows.length, 2); // Dumbbell Press + Cable Tri

    final psRows = await db.select(db.plannedSets).get();
    expect(psRows.length, 4); // 2 sets × 2 exercises

    // Cold start: all reps/weight null.
    expect(psRows.every((s) => s.reps == null && s.weight == null), true);
  });

  test('4. generatePlannedWorkout is idempotent', () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final workout = await db.getOrCreateNextWorkout(mesoId);

    await db.generatePlannedWorkout(workout!.id);
    await db.generatePlannedWorkout(workout.id); // call twice

    final pwRows = await db.select(db.plannedWorkouts).get();
    expect(pwRows.length, 1); // still only one
    expect((await db.select(db.plannedSets).get()).length, 4);
  });

  test('5. initializeWorkout creates active completed_workout with correct exercises/sets',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final workout = await db.getOrCreateNextWorkout(mesoId);

    await db.generatePlannedWorkout(workout!.id);
    final cwId = await db.initializeWorkout(workout.id);

    final cwRows = await db.select(db.completedWorkouts).get();
    expect(cwRows.length, 1);
    expect(cwRows.first.id, cwId);
    expect(cwRows.first.status, WorkoutStatus.active);
    expect(cwRows.first.completedAt, isNull);

    final ceRows = await (db.select(db.completedExercises)
          ..where((e) => e.completedWorkoutId.equals(cwId)))
        .get();
    expect(ceRows.length, 2); // Dumbbell Press + Cable Tri

    final allSets = await db.select(db.completedSets).get();
    expect(allSets.length, 4); // 2 sets × 2 exercises
    expect(allSets.every((s) => s.reps == null && s.weight == null), true);

    // app_state removed; currentCompletedWorkoutId now lives in AppPreferences.
  });

  test('6. savePreWorkoutCheckin inserts correct row', () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final workout = await db.getOrCreateNextWorkout(mesoId);

    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: workout!.id,
      quads: const Value(Soreness.some),
      chest: const Value(Soreness.aLittle),
      sleepQuality: const Value(CurrentState.good),
    ));

    final rows = await db.select(db.preWorkoutCheckins).get();
    expect(rows.length, 1);
    expect(rows.first.workoutId, workout.id);
    expect(rows.first.quads, Soreness.some);
    expect(rows.first.chest, Soreness.aLittle);
    expect(rows.first.sleepQuality, CurrentState.good);
  });

  test('7. After completing Day 1, getOrCreateNextWorkout creates rest day and returns Day 3',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final day1 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, day1!.id);

    final next = await db.getOrCreateNextWorkout(mesoId);
    expect(next, isNotNull);
    expect(next!.name, 'Day 3');
    expect(next.isRestDay, false);

    // Day 2 rest day row should now exist and be completed.
    final workoutRows = await db.select(db.workouts).get();
    final restDay = workoutRows.firstWhere((w) => w.isRestDay);
    expect(restDay.name, 'Day 2');

    final completedRows = await (db.select(db.completedWorkouts)
          ..where((cw) => cw.workoutId.equals(restDay.id)))
        .get();
    expect(completedRows.length, 1);
  });

  test('8. After completing all week 1 training, getOrCreateNextWorkout creates week 2',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);

    // Complete Day 1.
    final day1 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, day1!.id);

    // Complete Day 3.
    final day3 = await db.getOrCreateNextWorkout(mesoId);
    expect(day3!.name, 'Day 3');
    await _completeWorkoutFull(db, day3.id);

    // Next call should create week 2.
    final week2day1 = await db.getOrCreateNextWorkout(mesoId);
    expect(week2day1, isNotNull);
    expect(week2day1!.name, 'Day 1'); // same slot name from prior week template

    final weekRows = await (db.select(db.weeks)
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();
    expect(weekRows.length, 2);
    expect(weekRows[1].weekNumber, 2);
    expect(weekRows[1].goal, WeekGoal.deload); // last week = deload
  });

  test('9. Mesocycle complete: getOrCreateNextWorkout returns null after all weeks done',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 2);

    // Complete week 1.
    final w1d1 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, w1d1!.id);
    final w1d3 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, w1d3!.id);

    // Complete week 2.
    final w2d1 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, w2d1!.id);
    final w2d3 = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, w2d3!.id);

    final done = await db.getOrCreateNextWorkout(mesoId);
    expect(done, isNull);
  });

  test('10. Full flow: create meso → getOrCreate → checkin → generatePlanned → initializeWorkout',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);

    // Verify no mesocycle rows existed before.
    final workout = await db.getOrCreateNextWorkout(mesoId);
    expect(workout, isNotNull);
    expect(workout!.name, 'Day 1');

    // Save check-in.
    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: workout.id,
    ));

    // Generate planned workout + initialize.
    await db.generatePlannedWorkout(workout.id);
    final cwId = await db.initializeWorkout(workout.id);

    final checkins = await db.select(db.preWorkoutCheckins).get();
    expect(checkins.length, 1);
    expect(checkins.first.workoutId, workout.id);

    final cw = await (db.select(db.completedWorkouts)
          ..where((w) => w.id.equals(cwId)))
        .getSingle();
    expect(cw.status, WorkoutStatus.active);
    expect(cw.completedAt, isNull);

    final exercises = await (db.select(db.completedExercises)
          ..where((e) => e.completedWorkoutId.equals(cwId)))
        .get();
    expect(exercises.length, 2);

    final allSets = await db.select(db.completedSets).get();
    expect(allSets.length, 4);
    expect(allSets.every((s) => s.reps == null && s.weight == null), true);
  });
}
