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
    // Set counts: 2 or 3 (M=1 exercises in prior meso W=2 got a heuristic-
    // added 3rd set; the test fills all of them, so they propagate forward).
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
      expect(plannedSets.length, anyOf(2, 3));
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

  // ── Add / remove weeks ───────────────────────────────────────────────────

  test('14. addHardWeek bumps totalWeekCount before any week materialized',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 3);
    // No weeks materialized yet.
    expect(await db.canAddHardWeek(mesoId), true);
    expect(await db.canRemoveWeek(mesoId), true);

    await db.addHardWeek(mesoId);

    final meso = await (db.select(db.mesocycles)
          ..where((m) => m.id.equals(mesoId)))
        .getSingle();
    expect(meso.totalWeekCount, 4);
    final weekRows = await db.select(db.weeks).get();
    expect(weekRows, isEmpty,
        reason: 'No weeks materialized prior — none created by addHardWeek');
  });

  test('15. addHardWeek flips materialized deload to hard and clears plans',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // 2-week meso: complete week 1, deload (week 2) gets materialized.
    final mesoId = await _createMeso(db, totalWeeks: 2);
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }
    // First workout of deload week materialized; its plan generated.
    final deloadStart = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(deloadStart!.id);
    final plannedBefore = await db.select(db.plannedWorkouts).get();
    expect(plannedBefore.length, 6,
        reason: 'Plans for all completed workouts + the deload day');

    final weekRowsBefore = await (db.select(db.weeks)
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();
    expect(weekRowsBefore[1].goal, WeekGoal.deload);

    expect(await db.canAddHardWeek(mesoId), true);
    await db.addHardWeek(mesoId);

    final meso = await (db.select(db.mesocycles)
          ..where((m) => m.id.equals(mesoId)))
        .getSingle();
    expect(meso.totalWeekCount, 3);

    final weekRowsAfter = await (db.select(db.weeks)
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();
    expect(weekRowsAfter[1].goal, WeekGoal.hard,
        reason: 'Deload should have flipped to hard');

    // Planned data for the (formerly-deload) week should be gone, so it
    // regenerates as a hard week on next open.
    final plannedAfter = await (db.select(db.plannedWorkouts).join([
      innerJoin(db.workouts,
          db.workouts.id.equalsExp(db.plannedWorkouts.workoutId)),
    ])
          ..where(db.workouts.weekId.equals(weekRowsAfter[1].id)))
        .get();
    expect(plannedAfter, isEmpty);
  });

  test('16. canAddHardWeek is false once deload workout has started', () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 2);
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }
    final deloadDay = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(deloadDay!.id);
    await db.initializeWorkout(deloadDay.id);

    expect(await db.canAddHardWeek(mesoId), false);
    expect(await db.canRemoveWeek(mesoId), false);
    await expectLater(db.addHardWeek(mesoId), throwsA(isA<StateError>()));
  });

  test('17. removeWeek deletes materialized future week with plans', () async {
    final db = _openDb();
    addTearDown(db.close);

    // 2-week meso: complete week 1 so week 2 (deload) materializes.
    final mesoId = await _createMeso(db, totalWeeks: 2);
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }
    // Materialize first deload workout + its plan.
    final deloadStart = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(deloadStart!.id);

    // Bump to 3 weeks first so week 2 is hard (we want to remove a future
    // hard week and have week 2 flip back to deload).
    await db.addHardWeek(mesoId);
    // Now totalWeekCount=3, week 2 is hard. canRemoveWeek floor is 2 (last
    // occupied + 1), so removeWeek should bring it back to 2 with week 2 as
    // deload again.

    expect(await db.canRemoveWeek(mesoId), true);
    await db.removeWeek(mesoId);

    final meso = await (db.select(db.mesocycles)
          ..where((m) => m.id.equals(mesoId)))
        .getSingle();
    expect(meso.totalWeekCount, 2);

    final weekRows = await (db.select(db.weeks)
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();
    expect(weekRows.length, 2);
    expect(weekRows[1].goal, WeekGoal.deload);

    // Plans for week 2 cleared so they regenerate as deload.
    final plansForWeek2 = await (db.select(db.plannedWorkouts).join([
      innerJoin(db.workouts,
          db.workouts.id.equalsExp(db.plannedWorkouts.workoutId)),
    ])
          ..where(db.workouts.weekId.equals(weekRows[1].id)))
        .get();
    expect(plansForWeek2, isEmpty);

    // canRemoveWeek is now false: floor is 2, totalWeekCount is 2.
    expect(await db.canRemoveWeek(mesoId), false);
  });

  test('18. removeWeek floor: cannot remove past lastOccupied + 1', () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 4);
    // Complete week 1 (5 days), then start (initialize) the first workout of
    // week 2 — that occupies week 2.
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }
    final week2Day1 = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(week2Day1!.id);
    await db.initializeWorkout(week2Day1.id);

    // lastOccupied = 2, floor = 3, totalWeekCount = 4 → can remove once.
    expect(await db.canRemoveWeek(mesoId), true);
    await db.removeWeek(mesoId);
    var meso = await (db.select(db.mesocycles)
          ..where((m) => m.id.equals(mesoId)))
        .getSingle();
    expect(meso.totalWeekCount, 3);

    // Now totalWeekCount = 3 = floor → cannot remove again.
    expect(await db.canRemoveWeek(mesoId), false);
    await expectLater(db.removeWeek(mesoId), throwsA(isA<StateError>()));
  });

  test('19. removeWeek flips current materialized week from hard to deload',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // 3-week meso. Materialize week 1 only (don't complete it). Week 1's
    // goal is currently 'hard'. canRemoveWeek floor is 1 (no occupied week).
    final mesoId = await _createMeso(db, totalWeeks: 3);
    final week1Day1 = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(week1Day1!.id);

    expect(await db.canRemoveWeek(mesoId), true);
    await db.removeWeek(mesoId); // totalWeekCount: 3 → 2
    expect(await db.canRemoveWeek(mesoId), true);
    await db.removeWeek(mesoId); // totalWeekCount: 2 → 1

    final meso = await (db.select(db.mesocycles)
          ..where((m) => m.id.equals(mesoId)))
        .getSingle();
    expect(meso.totalWeekCount, 1);

    final weekRows = await db.select(db.weeks).get();
    expect(weekRows.length, 1);
    expect(weekRows.first.goal, WeekGoal.deload,
        reason: 'Week 1 should have flipped to deload as the new last week');

    // Plan for week 1's day 1 should have been cleared so it regenerates.
    final plans = await db.select(db.plannedWorkouts).get();
    expect(plans, isEmpty);

    // Floor reached.
    expect(await db.canRemoveWeek(mesoId), false);
  });

  test('20. getMesoProgress reports cycle position with deload flag',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 2);
    final monday = await db.getOrCreateNextWorkout(mesoId);
    final progress = await db.getMesoProgress(mesoId, monday!.id);
    expect(progress.weekNumber, 1);
    expect(progress.totalWeekCount, 2);
    expect(progress.trainingDayIndex, 1);
    expect(progress.totalTrainingDaysThisWeek, 5);
    expect(progress.isDeloadWeek, false);
    expect(progress.canAddHardWeek, true);
    expect(progress.canRemoveWeek, true);

    // Complete week 1, land on deload week 2 day 1.
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }
    final deloadDay = await db.getOrCreateNextWorkout(mesoId);
    final deloadProgress = await db.getMesoProgress(mesoId, deloadDay!.id);
    expect(deloadProgress.weekNumber, 2);
    expect(deloadProgress.totalWeekCount, 2);
    expect(deloadProgress.trainingDayIndex, 1);
    expect(deloadProgress.isDeloadWeek, true);
    expect(deloadProgress.canAddHardWeek, true);
    // Floor = lastOccupied+1 = 2, totalWeekCount = 2 → cannot remove.
    expect(deloadProgress.canRemoveWeek, false);
  });

  // ── Auto set-count progression ───────────────────────────────────────────

  /// Fills every completed_set in [cwId] with the given reps/weight, then
  /// finishes the workout. Used to seed prior-week values for heuristic tests.
  Future<void> finishWithSetValues(
      AppDatabase db, int cwId, int reps, double weight) async {
    final sets = await (db.select(db.completedSets).join([
      innerJoin(db.completedExercises,
          db.completedExercises.id.equalsExp(db.completedSets.completedExerciseId)),
    ])
          ..where(db.completedExercises.completedWorkoutId.equals(cwId)))
        .map((row) => row.readTable(db.completedSets))
        .get();
    for (final s in sets) {
      await db.saveCompletedSet(s.id, reps: reps, weight: weight);
    }
    await db.finishWorkout(cwId);
  }

  test('21. Auto set progression: W=2 hard week adds set to M=1 exercises only',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // 3-week meso: hard, hard, deload.
    final mesoId = await _createMeso(db, totalWeeks: 3);

    // Monday W=1: 5 exercises (back×2, biceps, shoulders, abs), 2 sets each.
    // Complete with reps=8, weight=100.
    final w1Monday = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(w1Monday!.id);
    final w1cw = await db.initializeWorkout(w1Monday.id);
    await finishWithSetValues(db, w1cw, 8, 100.0);

    // Complete the rest of W=1 quickly (no values needed for this test).
    for (var i = 0; i < 4; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    // W=2 Monday: expect 14 planned sets.
    // M=1 of each muscle group (Bent Over Row=back, Curl=biceps, Lateral
    // Raise=shoulders, Leg Raise=abs) gets a 3rd null set. Pullover (back,
    // M=2) keeps 2 sets.
    final w2Monday = await db.getOrCreateNextWorkout(mesoId);
    expect(w2Monday!.name, 'Monday');
    await db.generatePlannedWorkout(w2Monday.id);

    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(w2Monday.id)))
        .getSingle();
    final exs = await (db.select(db.plannedExercises).join([
      innerJoin(db.movements,
          db.movements.id.equalsExp(db.plannedExercises.movementId)),
    ])
          ..where(db.plannedExercises.plannedWorkoutId.equals(pw.id))
          ..orderBy([OrderingTerm.asc(db.plannedExercises.id)]))
        .map((row) => (
              pe: row.readTable(db.plannedExercises),
              mv: row.readTable(db.movements),
            ))
        .get();
    expect(exs.length, 5);

    final setsByMovement = <String, List<PlannedSet>>{};
    var totalSets = 0;
    for (final e in exs) {
      final sets = await (db.select(db.plannedSets)
            ..where((s) => s.plannedExerciseId.equals(e.pe.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
      setsByMovement[e.mv.name] = sets;
      totalSets += sets.length;
    }
    expect(totalSets, 14);

    // Pullover is M=2 within back muscle group — no extra set.
    expect(setsByMovement['Barbell Pullover']!.length, 2,
        reason: 'M=2 in muscle group: no extra set on even W');

    // The other four exercises are M=1 in their muscle group — extra set.
    for (final name in [
      'Barbell Bent Over Row',
      'Dumbbell Curl (Lying)',
      'Dumbbell Lateral Raise',
      'Hanging Straight Leg Raise',
    ]) {
      final sets = setsByMovement[name]!;
      expect(sets.length, 3, reason: '$name (M=1) should get +1 set');
      // First 2 sets keep prior values with +1 rep bump (autoProgress default true).
      expect(sets[0].reps, 9);
      expect(sets[1].reps, 9);
      // The new set inherits weight like the manual "Add Set" flow, while
      // reps remain empty for the user to record.
      expect(sets[2].reps, isNull);
      expect(sets[2].weight, 100.0);
    }
  });

  test('22. Auto set progression: W=3 odd hard week adds set to M=2 only',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    // 4-week meso: hard, hard, hard, deload — so W=3 is hard.
    final templates = await db.getMesoTemplates();
    final mesoId =
        await db.createMesocycle(templates.first.id, 'Test Meso', 4);

    // W=1 Monday with reps=8.
    final w1Monday = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(w1Monday!.id);
    final w1cw = await db.initializeWorkout(w1Monday.id);
    await finishWithSetValues(db, w1cw, 8, 100.0);

    // Complete rest of W=1.
    for (var i = 0; i < 4; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    // W=2 Monday — fill all sets (including extras) with reps=9.
    final w2Monday = await db.getOrCreateNextWorkout(mesoId);
    expect(w2Monday!.name, 'Monday');
    await db.generatePlannedWorkout(w2Monday.id);
    final w2cw = await db.initializeWorkout(w2Monday.id);
    await finishWithSetValues(db, w2cw, 9, 100.0);

    // Complete rest of W=2.
    for (var i = 0; i < 4; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    // W=3 Monday: M=2 (Pullover) gets +1, M=1 exercises keep their W=2 counts.
    final w3Monday = await db.getOrCreateNextWorkout(mesoId);
    expect(w3Monday!.name, 'Monday');
    await db.generatePlannedWorkout(w3Monday.id);

    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(w3Monday.id)))
        .getSingle();
    final exs = await (db.select(db.plannedExercises).join([
      innerJoin(db.movements,
          db.movements.id.equalsExp(db.plannedExercises.movementId)),
    ])
          ..where(db.plannedExercises.plannedWorkoutId.equals(pw.id))
          ..orderBy([OrderingTerm.asc(db.plannedExercises.id)]))
        .map((row) => (
              pe: row.readTable(db.plannedExercises),
              mv: row.readTable(db.movements),
            ))
        .get();

    final setsByMovement = <String, List<PlannedSet>>{};
    for (final e in exs) {
      setsByMovement[e.mv.name] = await (db.select(db.plannedSets)
            ..where((s) => s.plannedExerciseId.equals(e.pe.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
    }

    // Pullover (M=2): 2 in W=2 → +1 → 3 in W=3. Third set is empty.
    final pullover = setsByMovement['Barbell Pullover']!;
    expect(pullover.length, 3, reason: 'M=2 on odd W>1 should get +1 set');
    expect(pullover[2].reps, isNull);

    // M=1 exercises: 3 in W=2 → stay at 3 in W=3 (no extra), all with reps=10.
    for (final name in [
      'Barbell Bent Over Row',
      'Dumbbell Curl (Lying)',
      'Dumbbell Lateral Raise',
      'Hanging Straight Leg Raise',
    ]) {
      final sets = setsByMovement[name]!;
      expect(sets.length, 3, reason: '$name (M=1) should not get extra on odd W');
      expect(sets.every((s) => s.reps == 10), true);
    }
  });

  test('23. Auto set progression: deload week does not add a set', () async {
    final db = _openDb();
    addTearDown(db.close);

    // 2-week meso: hard (W=1), deload (W=2).
    final mesoId = await _createMeso(db, totalWeeks: 2);

    // Finish W=1 with values.
    for (var i = 0; i < 5; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await db.generatePlannedWorkout(w!.id);
      final cwId = await db.initializeWorkout(w.id);
      await finishWithSetValues(db, cwId, 8, 100.0);
    }

    // W=2 (deload) Monday: every exercise stays at deload's reduced count
    // (ceil(2/3 * 2) = 2), never gets a heuristic-added extra set.
    final w2Monday = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(w2Monday!.id);
    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(w2Monday.id)))
        .getSingle();
    final exs = await (db.select(db.plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
        .get();

    for (final pe in exs) {
      final sets = await (db.select(db.plannedSets)
            ..where((s) => s.plannedExerciseId.equals(pe.id)))
          .get();
      expect(sets.length, 2,
          reason: 'Deload uses 2/3 of prior count, never +1 from heuristic');
    }
  });

  test('24. Auto set progression: autoProgress=false keeps original set count',
      () async {
    final db = _openDb();
    addTearDown(db.close);

    final mesoId = await _createMeso(db, totalWeeks: 3);

    // Finish W=1 with values.
    final w1Monday = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(w1Monday!.id);
    final w1cw = await db.initializeWorkout(w1Monday.id);

    // Turn off autoProgress for every exercise in W=1 Monday.
    final w1Exs = await (db.select(db.completedExercises)
          ..where((e) => e.completedWorkoutId.equals(w1cw)))
        .get();
    for (final ex in w1Exs) {
      await (db.update(db.completedExercises)
            ..where((e) => e.id.equals(ex.id)))
          .write(const CompletedExercisesCompanion(
              autoProgress: Value(false)));
    }

    await finishWithSetValues(db, w1cw, 8, 100.0);

    // Complete rest of W=1.
    for (var i = 0; i < 4; i++) {
      final w = await db.getOrCreateNextWorkout(mesoId);
      await _completeWorkoutFull(db, w!.id);
    }

    // W=2 Monday: every exercise should keep 2 sets (no progression, no bump).
    final w2Monday = await db.getOrCreateNextWorkout(mesoId);
    await db.generatePlannedWorkout(w2Monday!.id);
    final pw = await (db.select(db.plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(w2Monday.id)))
        .getSingle();
    final exs = await (db.select(db.plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
        .get();
    for (final pe in exs) {
      final sets = await (db.select(db.plannedSets)
            ..where((s) => s.plannedExerciseId.equals(pe.id)))
          .get();
      expect(sets.length, 2,
          reason: 'autoProgress off: no set bump even when W/M qualifies');
      // Also no rep bump: prior reps preserved.
      expect(sets.every((s) => s.reps == 8), true);
    }
  });
}
