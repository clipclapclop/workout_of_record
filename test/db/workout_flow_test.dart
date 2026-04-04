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
  // Seed data: movements + default template (Monday/Tuesday/Wednesday/Thursday/Friday,
  // all training days, no rest days), no mesocycle.

  test('1. Fresh meso: getOrCreateNextWorkout creates week 1 and returns Day 1',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final next = await db.getOrCreateNextWorkout(mesoId);

    expect(next, isNotNull);
    expect(next!.name, 'Monday');
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
    expect(peRows.length, 5); // 5 exercises from Monday slot

    final psRows = await db.select(db.plannedSets).get();
    expect(psRows.length, 10); // 2 sets × 5 exercises

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
    expect((await db.select(db.plannedSets).get()).length, 10);
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
    expect(ceRows.length, 5); // 5 exercises from Monday slot

    final allSets = await db.select(db.completedSets).get();
    expect(allSets.length, 10); // 2 sets × 5 exercises
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

  test('7. After completing Monday, getOrCreateNextWorkout returns Tuesday',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);
    final monday = await db.getOrCreateNextWorkout(mesoId);
    await _completeWorkoutFull(db, monday!.id);

    final next = await db.getOrCreateNextWorkout(mesoId);
    expect(next, isNotNull);
    expect(next!.name, 'Tuesday');
    expect(next.isRestDay, false);

    // Only 2 workout rows: Monday (completed) + Tuesday (ready).
    final workoutRows = await db.select(db.workouts).get();
    expect(workoutRows.length, 2);
    expect(workoutRows.every((w) => !w.isRestDay), true);
  });

  test('8. After completing all week 1 training, getOrCreateNextWorkout creates week 2',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);

    // Complete all 5 training days in week 1 (Monday–Friday, no rest days).
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    // Next call should create week 2 starting from Monday.
    final week2day1 = await db.getOrCreateNextWorkout(mesoId);
    expect(week2day1, isNotNull);
    expect(week2day1!.name, 'Monday');

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

    // Complete all 5 days in week 1, then all 5 in week 2.
    for (var i = 0; i < 10; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    final done = await db.getOrCreateNextWorkout(mesoId);
    expect(done, isNull);
  });

  // ── Cross-meso seeding tests ─────────────────────────────────────────────

  test('11. Cross-meso seeding: week 1 of new meso uses 2nd hard week from prior meso',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // ── Meso 1: 3 weeks (hard, hard, deload) ──
    final meso1Id = await _createMeso(db, totalWeeks: 3);

    // Complete all 3 weeks with real set values.
    for (var week = 0; week < 3; week++) {
      for (var day = 0; day < 5; day++) {
        final w = await db.getOrCreateNextWorkout(meso1Id);
        await db.generatePlannedWorkout(w!.id);
        final cwId = await db.initializeWorkout(w.id);

        // Fill in set values: week1=100lb×8, week2=100lb×9, week3(deload)=65lb×8.
        final exercises = await (db.select(db.completedExercises)
              ..where((e) => e.completedWorkoutId.equals(cwId)))
            .get();
        for (final ex in exercises) {
          final sets = await (db.select(db.completedSets)
                ..where((s) => s.completedExerciseId.equals(ex.id)))
              .get();
          for (final s in sets) {
            final reps = week == 2 ? 8 : 8 + week; // w1: 8, w2: 9, w3: 8
            final weight =
                week == 2 ? 65.0 : 100.0; // w1: 100, w2: 100, w3: 65
            await db.saveCompletedSet(s.id, reps: reps, weight: weight);
          }
        }

        await db.finishWorkout(cwId);
      }
    }

    // Meso 1 should be done.
    expect(await db.getOrCreateNextWorkout(meso1Id), isNull);

    // ── Meso 2: new meso from same template ──
    final templates = await db.getMesoTemplates();
    final meso2Id =
        await db.createMesocycle(templates.first.id, 'Test Meso 2', 3);
    final firstWorkout = await db.getOrCreateNextWorkout(meso2Id);
    await db.generatePlannedWorkout(firstWorkout!.id);

    // Check that planned sets use week 2 values (2nd hard week): 100lb × 9 reps.
    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(firstWorkout.id)))
        .getSingle();
    final plannedExs = await (db.select(db.plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
        .get();

    for (final pe in plannedExs) {
      final plannedSets = await (db.select(db.plannedSets)
            ..where((ps) => ps.plannedExerciseId.equals(pe.id)))
          .get();
      expect(plannedSets.length, 2); // 2 sets (matching prior week's count)
      for (final ps in plannedSets) {
        expect(ps.reps, 9, reason: 'Should use week 2 reps (2nd hard week)');
        expect(ps.weight, 100.0,
            reason: 'Should use week 2 weight, not deload weight');
      }
    }
  });

  test('12. Cross-meso seeding: exercise with only 1 hard week uses that week',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // ── Meso 1: 2 weeks (hard, deload) — only 1 hard week ──
    final meso1Id = await _createMeso(db, totalWeeks: 2);

    for (var week = 0; week < 2; week++) {
      for (var day = 0; day < 5; day++) {
        final w = await db.getOrCreateNextWorkout(meso1Id);
        await db.generatePlannedWorkout(w!.id);
        final cwId = await db.initializeWorkout(w.id);

        final exercises = await (db.select(db.completedExercises)
              ..where((e) => e.completedWorkoutId.equals(cwId)))
            .get();
        for (final ex in exercises) {
          final sets = await (db.select(db.completedSets)
                ..where((s) => s.completedExerciseId.equals(ex.id)))
              .get();
          for (final s in sets) {
            final reps = week == 0 ? 10 : 10;
            final weight = week == 0 ? 80.0 : 52.0; // deload = 65% of 80
            await db.saveCompletedSet(s.id, reps: reps, weight: weight);
          }
        }

        await db.finishWorkout(cwId);
      }
    }

    expect(await db.getOrCreateNextWorkout(meso1Id), isNull);

    // ── Meso 2 ──
    final templates = await db.getMesoTemplates();
    final meso2Id =
        await db.createMesocycle(templates.first.id, 'Test Meso 2', 2);
    final firstWorkout = await db.getOrCreateNextWorkout(meso2Id);
    await db.generatePlannedWorkout(firstWorkout!.id);

    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(firstWorkout.id)))
        .getSingle();
    final plannedExs = await (db.select(db.plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
        .get();

    for (final pe in plannedExs) {
      final plannedSets = await (db.select(db.plannedSets)
            ..where((ps) => ps.plannedExerciseId.equals(pe.id)))
          .get();
      for (final ps in plannedSets) {
        expect(ps.reps, 10,
            reason: 'Should use the only hard week (week 1) reps');
        expect(ps.weight, 80.0,
            reason: 'Should use week 1 weight, not deload');
      }
    }
  });

  test('13. Cross-meso seeding: no prior meso falls back to cold start (null sets)',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // First ever meso — no prior history.
    final mesoId = await _createMeso(db, totalWeeks: 2);
    final workout = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(workout!.id);

    final psRows = await db.select(db.plannedSets).get();
    expect(psRows.length, 10); // 2 sets × 5 exercises
    expect(psRows.every((s) => s.reps == null && s.weight == null), true,
        reason: 'No prior meso — should be cold start with null values');
  });

  test('10. Full flow: create meso → getOrCreate → checkin → generatePlanned → initializeWorkout',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db);

    // Verify no mesocycle rows existed before.
    final workout = await db.getOrCreateNextWorkout(mesoId);
    expect(workout, isNotNull);
    expect(workout!.name, 'Monday');

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
    expect(exercises.length, 5); // 5 exercises from Monday slot

    final allSets = await db.select(db.completedSets).get();
    expect(allSets.length, 10); // 2 sets × 5 exercises
    expect(allSets.every((s) => s.reps == null && s.weight == null), true);
  });
}
