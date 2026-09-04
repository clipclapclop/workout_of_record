import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_preferences.dart';
import 'ai_planning.dart';
import 'calendar_data.dart';
import 'history_data.dart';
import 'seed/meso_template_seed_data.dart';
import 'seed/movement_seed_data.dart';
import 'planning.dart';
import 'template_data.dart';
import 'workout_data.dart';
import 'tables/checkins.dart';
import 'tables/enums.dart';
import 'tables/exercises.dart';
import 'tables/mesocycles.dart';
import 'tables/movements.dart';
import 'tables/sets.dart';
import 'tables/templates.dart';
import 'tables/workouts.dart';

part 'app_database.g.dart';

/// Oldest database schema that the app and restore pipeline can safely migrate.
///
/// Change this range deliberately alongside the migration fixtures documented in
/// `docs/maintainer/database-migrations.md`.
const minimumRestorableSchemaVersion = 8;
const currentDatabaseSchemaVersion = 13;

class ExerciseReplacementBlockedException implements Exception {
  const ExerciseReplacementBlockedException();
}

@DriftDatabase(tables: [
  Movements,
  MesoTemplates,
  WeekTemplates,
  WorkoutTemplates,
  ExerciseTemplates,
  Mesocycles,
  Weeks,
  Workouts,
  PlannedWorkouts,
  CompletedWorkouts,
  PlannedExercises,
  CompletedExercises,
  PlannedSets,
  CompletedSets,
  PreWorkoutCheckins,
  PostExerciseCheckins,
  PostMuscleGroupCheckins,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.withExecutor(super.e);

  /// AI recommendation errors from the most recent `generatePlannedWorkout` call.
  /// Empty if all exercises used AI successfully (or AI was disabled).
  final List<String> _lastAiErrors = [];

  /// Returns and clears any AI errors from the last plan generation.
  List<String> consumeAiErrors() {
    final errors = List<String>.from(_lastAiErrors);
    _lastAiErrors.clear();
    return errors;
  }

  @override
  int get schemaVersion => currentDatabaseSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedData();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          for (var version = from; version < to; version++) {
            switch (version) {
              case 8:
                // 8 → 9: Added pump_level to post_muscle_group_checkins.
                await customStatement(
                  "ALTER TABLE post_muscle_group_checkins "
                  "ADD COLUMN pump_level TEXT NOT NULL DEFAULT 'none'",
                );
              case 9:
                // 9 → 10: Replace isPersistent bool with Persistence intEnum;
                // remove unique constraint on (completedWorkoutId, orderIndex).
                // SQLite requires full table recreation to drop a constraint
                // and rename a column. FK checks are disabled for the swap so
                // that child tables (completed_sets, post_exercise_checkins,
                // etc.) don't block the DROP.
                await customStatement('PRAGMA foreign_keys = OFF');
                await customStatement('''
                  CREATE TABLE completed_exercises_new (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    completed_workout_id INTEGER NOT NULL
                      REFERENCES completed_workouts(id),
                    movement_id INTEGER NOT NULL
                      REFERENCES movements(id),
                    order_index INTEGER NOT NULL,
                    persistence INTEGER NOT NULL DEFAULT 0,
                    skip_reason TEXT
                  )
                ''');
                await customStatement('''
                  INSERT INTO completed_exercises_new
                    (id, completed_workout_id, movement_id, order_index,
                     persistence, skip_reason)
                  SELECT id, completed_workout_id, movement_id, order_index,
                    CASE WHEN is_persistent = 1 THEN 0 ELSE 2 END,
                    skip_reason
                  FROM completed_exercises
                ''');
                await customStatement('DROP TABLE completed_exercises');
                await customStatement(
                  'ALTER TABLE completed_exercises_new '
                  'RENAME TO completed_exercises',
                );
                await customStatement('PRAGMA foreign_keys = ON');
              case 10:
                // 10 → 11: Add aiPlanned flag to exercise_templates,
                // planned_exercises, and completed_exercises (default true).
                await customStatement(
                  'ALTER TABLE exercise_templates '
                  'ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1',
                );
                await customStatement(
                  'ALTER TABLE planned_exercises '
                  'ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1',
                );
                await customStatement(
                  'ALTER TABLE completed_exercises '
                  'ADD COLUMN ai_planned INTEGER NOT NULL DEFAULT 1',
                );
              case 11:
                // 11 → 12: Add tibialis soreness to pre_workout_checkins.
                await customStatement(
                  'ALTER TABLE pre_workout_checkins '
                  'ADD COLUMN tibialis TEXT',
                );
              case 12:
                // 12 → 13: Existing custom movements remain at zero;
                // recognized built-ins receive their seeded defaults.
                await m.addColumn(movements, movements.bodyweightLoadFraction);
                for (final seed in kMovementSeeds
                    .where((seed) => seed.bodyweightLoadFraction != 0)) {
                  await (update(movements)
                        ..where((movement) =>
                            movement.name.equals(seed.name) &
                            movement.muscleGroup.equalsValue(seed.muscleGroup)))
                      .write(MovementsCompanion(
                    bodyweightLoadFraction:
                        Value(seed.bodyweightLoadFraction),
                  ));
                }
            }
          }
        },
      );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Creates a new mesocycle from the given template. Returns the new ID.
  /// Caller is responsible for updating AppPreferences with the returned ID.
  Future<int> createMesocycle(
      int templateId, String name, int totalWeeks) async {
    return into(mesocycles).insert(
      MesocyclesCompanion.insert(
        mesoTemplateId: templateId,
        name: name,
        totalWeekCount: totalWeeks,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> endMesocycleEarly(int mesocycleId) =>
      (update(mesocycles)..where((m) => m.id.equals(mesocycleId)))
          .write(MesocyclesCompanion(completedAt: Value(DateTime.now())));

  /// Returns cycle progress info for the start-workout screen, plus the
  /// gating flags for the add/remove-week affordances.
  Future<MesoProgressInfo> getMesoProgress(
      int mesocycleId, int workoutId) async {
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(mesocycleId)))
        .getSingle();
    final workout =
        await (select(workouts)..where((w) => w.id.equals(workoutId)))
            .getSingle();
    final allWeeks = await (select(weeks)
          ..where((w) => w.mesocycleId.equals(mesocycleId))
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();
    final currentWeek = allWeeks.firstWhere((w) => w.id == workout.weekId);
    final slots = await _getWeekTemplateSlots(currentWeek, allWeeks);
    final trainingSlots = slots.where((s) => !s.isRestDay).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final trainingDayIndex =
        trainingSlots.indexWhere((s) => s.orderIndex == workout.orderIndex) +
            1;

    return MesoProgressInfo(
      weekNumber: currentWeek.weekNumber,
      totalWeekCount: meso.totalWeekCount,
      trainingDayIndex: trainingDayIndex,
      totalTrainingDaysThisWeek: trainingSlots.length,
      isDeloadWeek: currentWeek.goal == WeekGoal.deload,
      canAddHardWeek: await canAddHardWeek(mesocycleId),
      canRemoveWeek: await canRemoveWeek(mesocycleId),
    );
  }

  /// True iff the user can extend this meso by one hard week right now.
  /// Allowed unless the meso is completed or any non-rest deload workout
  /// has already been started.
  Future<bool> canAddHardWeek(int mesocycleId) async {
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(mesocycleId)))
        .getSingleOrNull();
    if (meso == null || meso.completedAt != null) return false;

    final row = await (select(completedWorkouts).join([
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
    ])
          ..where(weeks.mesocycleId.equals(mesocycleId) &
              weeks.goal.equals(WeekGoal.deload.name) &
              workouts.isRestDay.equals(false))
          ..limit(1))
        .getSingleOrNull();
    return row == null;
  }

  /// True iff the user can shrink this meso by one week right now.
  /// Floor is `max(lastOccupiedWeek, 0) + 1` — never below the last week
  /// that already contains real (non-rest) completed work.
  Future<bool> canRemoveWeek(int mesocycleId) async {
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(mesocycleId)))
        .getSingleOrNull();
    if (meso == null || meso.completedAt != null) return false;
    final occupied = await _lastOccupiedWeekNumber(mesocycleId);
    final floor = occupied > 0 ? occupied + 1 : 1;
    return meso.totalWeekCount > floor;
  }

  /// Extends the meso by one hard week. If the deload week is already
  /// materialized, flips its goal to hard and wipes its planned data so it
  /// regenerates as a hard week the next time it's opened. The new deload
  /// week is materialized lazily later by [getOrCreateNextWorkout].
  Future<void> addHardWeek(int mesocycleId) async {
    await transaction(() async {
      if (!await canAddHardWeek(mesocycleId)) {
        throw StateError('Cannot add hard week: deload already started '
            'or mesocycle completed.');
      }
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(mesocycleId)))
          .getSingle();

      final deload = await (select(weeks)
            ..where((w) =>
                w.mesocycleId.equals(mesocycleId) &
                w.goal.equals(WeekGoal.deload.name)))
          .getSingleOrNull();
      if (deload != null) {
        await (update(weeks)..where((w) => w.id.equals(deload.id)))
            .write(const WeeksCompanion(goal: Value(WeekGoal.hard)));
        await _clearPlannedDataForWeek(deload.id);
      }

      await (update(mesocycles)..where((m) => m.id.equals(mesocycleId)))
          .write(MesocyclesCompanion(
              totalWeekCount: Value(meso.totalWeekCount + 1)));
    });
  }

  /// Shrinks the meso by one week. Deletes any materialized weeks past the
  /// new count (planned data and workouts go with them). If the new last
  /// week is already materialized as hard, flips it to deload and wipes its
  /// planned data so it regenerates as a deload week.
  Future<void> removeWeek(int mesocycleId) async {
    await transaction(() async {
      if (!await canRemoveWeek(mesocycleId)) {
        throw StateError('Cannot remove week: at floor or mesocycle '
            'completed.');
      }
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(mesocycleId)))
          .getSingle();
      final newCount = meso.totalWeekCount - 1;

      final toRemove = await (select(weeks)
            ..where((w) =>
                w.mesocycleId.equals(mesocycleId) &
                w.weekNumber.isBiggerThanValue(newCount)))
          .get();
      for (final w in toRemove) {
        await _deleteWeekAndContents(w.id);
      }

      final newLast = await (select(weeks)
            ..where((w) =>
                w.mesocycleId.equals(mesocycleId) &
                w.weekNumber.equals(newCount)))
          .getSingleOrNull();
      if (newLast != null && newLast.goal != WeekGoal.deload) {
        await (update(weeks)..where((w) => w.id.equals(newLast.id)))
            .write(const WeeksCompanion(goal: Value(WeekGoal.deload)));
        await _clearPlannedDataForWeek(newLast.id);
      }

      await (update(mesocycles)..where((m) => m.id.equals(mesocycleId)))
          .write(MesocyclesCompanion(totalWeekCount: Value(newCount)));
    });
  }

  /// Highest weekNumber for which any non-rest workout in the meso has a
  /// `completed_workouts` row. Returns 0 if none.
  Future<int> _lastOccupiedWeekNumber(int mesocycleId) async {
    final result = await (select(weeks).join([
      innerJoin(workouts, workouts.weekId.equalsExp(weeks.id)),
      innerJoin(
          completedWorkouts, completedWorkouts.workoutId.equalsExp(workouts.id)),
    ])
          ..where(weeks.mesocycleId.equals(mesocycleId) &
              workouts.isRestDay.equals(false))
          ..orderBy([OrderingTerm.desc(weeks.weekNumber)])
          ..limit(1))
        .getSingleOrNull();
    if (result == null) return 0;
    return result.readTable(weeks).weekNumber;
  }

  Future<void> _deleteWeekAndContents(int weekId) async {
    final wkts =
        await (select(workouts)..where((w) => w.weekId.equals(weekId))).get();
    for (final w in wkts) {
      await _deletePlannedForWorkout(w.id);
      await (delete(workouts)..where((row) => row.id.equals(w.id))).go();
    }
    await (delete(weeks)..where((w) => w.id.equals(weekId))).go();
  }

  Future<void> _clearPlannedDataForWeek(int weekId) async {
    final wkts =
        await (select(workouts)..where((w) => w.weekId.equals(weekId))).get();
    for (final w in wkts) {
      await _deletePlannedForWorkout(w.id);
    }
  }

  Future<void> _deletePlannedForWorkout(int workoutId) async {
    final pws = await (select(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(workoutId)))
        .get();
    for (final pw in pws) {
      final pes = await (select(plannedExercises)
            ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
          .get();
      for (final pe in pes) {
        await (delete(plannedSets)
              ..where((ps) => ps.plannedExerciseId.equals(pe.id)))
            .go();
      }
      await (delete(plannedExercises)
            ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
          .go();
    }
    await (delete(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(workoutId)))
        .go();
  }

  /// Returns the next workout to perform, creating week/workout rows as needed.
  ///
  /// This is the single entry point for all lazy materialization:
  /// - First call ever: creates week 1 + first training day workout row.
  /// - Subsequent calls: advances rest days, creates next training day row, or
  ///   creates the next week when the current one is training-complete.
  /// - Returns null when all weeks are done (mesocycle complete).
  Future<Workout?> getOrCreateNextWorkout(int mesocycleId) async {
    return await transaction(() async {
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(mesocycleId)))
          .getSingle();

      final existingWeeks = await (select(weeks)
            ..where((w) => w.mesocycleId.equals(mesocycleId))
            ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
          .get();

      // ── No weeks yet: bootstrap week 1 ─────────────────────────────────────
      if (existingWeeks.isEmpty) {
        final goal =
            meso.totalWeekCount == 1 ? WeekGoal.deload : WeekGoal.hard;
        final weekId = await _createWeek(mesocycleId, 1, goal);
        return await _materializeFirstTrainingDay(weekId, mesocycleId, null);
      }

      final currentWeek = existingWeeks.last;
      final currentWeekWorkouts = await (select(workouts)
            ..where((w) => w.weekId.equals(currentWeek.id))
            ..orderBy([(w) => OrderingTerm.asc(w.orderIndex)]))
          .get();

      // ── Find first workout without a completed_workout row ──────────────────
      for (final w in currentWeekWorkouts) {
        final completed = await (select(completedWorkouts)
              ..where((cw) => cw.workoutId.equals(w.id)))
            .getSingleOrNull();
        if (completed == null) return w; // In-progress or ready to start.
      }

      // All materialized workouts in this week are done.
      // Count training days done vs. expected from template/prior week.
      final templateSlots =
          await _getWeekTemplateSlots(currentWeek, existingWeeks);
      final trainingSlots =
          templateSlots.where((s) => !s.isRestDay).toList();
      final doneTraining =
          currentWeekWorkouts.where((w) => !w.isRestDay).length;

      // ── More training days left in this week ────────────────────────────────
      if (doneTraining < trainingSlots.length) {
        final nextSlot = trainingSlots[doneTraining];
        final lastCompleted = await _lastCompletedDate(mesocycleId);
        await _advanceRestDaysBefore(
          currentWeek.id,
          nextSlot.orderIndex,
          templateSlots,
          currentWeekWorkouts,
          lastCompleted,
        );
        return await _materializeTrainingDay(
          currentWeek.id,
          nextSlot.orderIndex,
          nextSlot.name,
        );
      }

      // ── All training done for this week ─────────────────────────────────────
      if (currentWeek.weekNumber >= meso.totalWeekCount) {
        await _markMesocycleCompleteIfFinished(mesocycleId);
        return null; // Mesocycle complete.
      }

      // Advance any remaining rest days for the completed week.
      final lastCompleted = await _lastCompletedDate(mesocycleId);
      await _advanceRestDaysBefore(
        currentWeek.id,
        templateSlots.last.orderIndex + 1, // "past the end"
        templateSlots,
        currentWeekWorkouts,
        lastCompleted,
      );

      // Create the next week, using current week's rows as the structural template.
      final nextWeekNumber = currentWeek.weekNumber + 1;
      final goal = nextWeekNumber == meso.totalWeekCount
          ? WeekGoal.deload
          : WeekGoal.hard;
      final nextWeekId = await _createWeek(mesocycleId, nextWeekNumber, goal);
      return await _materializeFirstTrainingDay(
          nextWeekId, mesocycleId, currentWeek.id);
    });
  }

  /// Generates planned_workout + planned_exercises + planned_sets for a workout.
  ///
  /// Idempotent — safe to call even if already generated.
  /// Week 1: seeded from the meso template (2 null sets per exercise).
  /// Week 2+: based on prior week's persistent completed exercises via heuristic.
  Future<void> generatePlannedWorkout(int workoutId) async {
    _lastAiErrors.clear();

    Workout? workoutForAi;
    Week? weekForAi;
    List<_PlanSeed> seeds = const [];

    // Phase 1: seed everything with heuristic values inside a fast transaction.
    // No HTTP calls here — the DB write lock is released before any AI work.
    await transaction(() async {
      final existing = await (select(plannedWorkouts)
            ..where((pw) => pw.workoutId.equals(workoutId)))
          .getSingleOrNull();
      if (existing != null) return;

      final workout =
          await (select(workouts)..where((w) => w.id.equals(workoutId)))
              .getSingle();
      final week =
          await (select(weeks)..where((w) => w.id.equals(workout.weekId)))
              .getSingle();
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(week.mesocycleId)))
          .getSingle();

      final plannedWorkoutId = await into(plannedWorkouts)
          .insert(PlannedWorkoutsCompanion.insert(workoutId: workoutId));

      if (week.weekNumber == 1) {
        await _generateFromTemplate(
            plannedWorkoutId, workout.orderIndex, meso.mesoTemplateId,
            meso.id);
      } else {
        seeds = await _seedFromPriorWeeks(plannedWorkoutId, workout, week);
        workoutForAi = workout;
        weekForAi = week;
      }
    });

    // Phase 2: refine autoProgress exercises with a single batched AI call.
    // Runs outside the transaction so the SQLite write lock isn't held while
    // we're on the network.
    if (workoutForAi != null && weekForAi != null && seeds.isNotEmpty) {
      await _applyBatchAiToSeeds(workoutForAi!, weekForAi!, seeds);
    }
  }

  /// Seeds the plan from the meso template (week 1).
  /// If the movement was used in a prior completed meso, seeds from the 2nd
  /// hard-week occurrence (or 1st if only one). Otherwise cold start: 2 null sets.
  Future<void> _generateFromTemplate(int plannedWorkoutId, int orderIndex,
      int mesoTemplateId, int currentMesocycleId) async {
    final wts = await (select(workoutTemplates).join([
      innerJoin(weekTemplates,
          weekTemplates.id.equalsExp(workoutTemplates.weekTemplateId)),
    ])
          ..where(weekTemplates.mesoTemplateId.equals(mesoTemplateId) &
              workoutTemplates.dayIndex.equals(orderIndex))
          ..limit(1))
        .map((row) => row.readTable(workoutTemplates))
        .getSingleOrNull();

    if (wts == null) return; // Rest day or no template match — empty plan.

    final exTemplates = await (select(exerciseTemplates)
          ..where((et) => et.workoutTemplateId.equals(wts.id))
          ..orderBy([(et) => OrderingTerm.asc(et.exerciseIndex)]))
        .get();

    for (final et in exTemplates) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(et.movementId)))
          .getSingle();

      final peId = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: plannedWorkoutId,
          movementId: et.movementId,
          autoProgress: Value(et.autoProgress),
        ),
      );

      final historicalSets = await _resolveHistoricalSets(
          et.movementId, currentMesocycleId, movement);

      for (final sv in historicalSets) {
        await into(plannedSets).insert(PlannedSetsCompanion(
          plannedExerciseId: Value(peId),
          reps: Value(sv.reps),
          weight: Value(sv.weight),
          time: Value(sv.time),
        ));
      }
    }
  }

  /// Seeds the plan from the prior week's persistent completed exercises (week 2+).
  /// Uses heuristic values only — AI refinement happens after the transaction
  /// commits. Returns one [_PlanSeed] per exercise that wants AI refinement.
  Future<List<_PlanSeed>> _seedFromPriorWeeks(
      int plannedWorkoutId, Workout workout, Week week) async {
    final allWeeks = await (select(weeks)
          ..where((w) => w.mesocycleId.equals(week.mesocycleId))
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();

    final priorWeek =
        allWeeks.firstWhere((w) => w.weekNumber == week.weekNumber - 1);
    final trainingSlots = (await _getWeekTemplateSlots(week, allWeeks))
        .where((slot) => !slot.isRestDay)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final workoutIndex = trainingSlots
        .indexWhere((slot) => slot.orderIndex == workout.orderIndex);
    final deloadType = deloadTypeForWorkout(
      workoutIndex < 0 ? 0 : workoutIndex,
      trainingSlots.length,
    );
    double? bodyWeight;
    try {
      bodyWeight = AppPreferences.getWeight();
    } catch (_) {
      // Preferences are intentionally absent in database-only tests.
    }
    final priorWorkout = await (select(workouts)
          ..where((w) =>
              w.weekId.equals(priorWeek.id) &
              w.orderIndex.equals(workout.orderIndex)))
        .getSingleOrNull();

    if (priorWorkout == null || priorWorkout.isRestDay) return const [];

    final priorCompleted = await (select(completedWorkouts)
          ..where((cw) => cw.workoutId.equals(priorWorkout.id)))
        .getSingleOrNull();
    if (priorCompleted == null) return const [];

    final priorExercises = await (select(completedExercises)
          ..where((ce) =>
              ce.completedWorkoutId.equals(priorCompleted.id) &
              ce.persistence.equals(Persistence.persistent.index))
          ..orderBy([(ce) => OrderingTerm.asc(ce.orderIndex)]))
        .get();

    // Pre-pass: load movements once, then assign each exercise a 1-based
    // position M within its muscle group (in orderIndex order).
    final movementById = <int, Movement>{};
    for (final priorEx in priorExercises) {
      movementById[priorEx.movementId] ??= await (select(movements)
            ..where((m) => m.id.equals(priorEx.movementId)))
          .getSingle();
    }
    final groupPositionByExId = <int, int>{};
    final perGroupCounter = <MuscleGroup, int>{};
    for (final priorEx in priorExercises) {
      final mg = movementById[priorEx.movementId]!.muscleGroup;
      final next = (perGroupCounter[mg] ?? 0) + 1;
      perGroupCounter[mg] = next;
      groupPositionByExId[priorEx.id] = next;
    }
    final w = week.weekNumber;
    bool addSetFor(int m) =>
        w >= 2 && ((w.isEven && m.isOdd) || (w.isOdd && m.isEven));

    final seeds = <_PlanSeed>[];
    for (final priorEx in priorExercises) {
      final movement = movementById[priorEx.movementId]!;

      final peId = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: plannedWorkoutId,
          movementId: priorEx.movementId,
          autoProgress: Value(priorEx.autoProgress),
        ),
      );

      final prior = await _findPriorSets(
          priorEx.movementId, workout.orderIndex, week, allWeeks);
      final m = groupPositionByExId[priorEx.id]!;
      final seedValues = prior == null
          ? const [PlannedSetValues(), PlannedSetValues()]
          : computeHeuristic(
              prior.nonSkipped, week.goal, movement, prior.totalCount,
              autoProgress: priorEx.autoProgress,
              addExtraSet: addSetFor(m),
              deloadType: deloadType,
              bodyWeight: bodyWeight,
            );

      for (final sv in seedValues) {
        await into(plannedSets).insert(PlannedSetsCompanion(
          plannedExerciseId: Value(peId),
          reps: Value(sv.reps),
          weight: Value(sv.weight),
          time: Value(sv.time),
        ));
      }

      if (priorEx.autoProgress && prior != null) {
        seeds.add(_PlanSeed(
          plannedExerciseId: peId,
          movement: movement,
          priorSets: prior.nonSkipped,
          targetCount: prior.totalCount,
        ));
      }
    }
    return seeds;
  }

  /// Runs a single batched AI call for all autoProgress-seeded exercises and
  /// rewrites their planned_sets rows. Falls back to the already-seeded
  /// heuristic values on failure.
  Future<void> _applyBatchAiToSeeds(
      Workout workout, Week week, List<_PlanSeed> seeds) async {
    if (seeds.isEmpty) return;

    final results = await computeBatchRecommendation(
      exercises: [
        for (final s in seeds)
          BatchExerciseInput(
            movement: s.movement,
            priorSets: s.priorSets,
            targetCount: s.targetCount,
          ),
      ],
      weekGoal: week.goal,
      mesocycleId: week.mesocycleId,
      weekNumber: week.weekNumber,
      workoutName: workout.name,
      workoutId: workout.id,
    );

    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final result = results[i];
      if (!result.usedAi) {
        if (result.error != null) _lastAiErrors.add(result.error!);
        continue;
      }
      await _rewritePlannedSets(seed.plannedExerciseId, result.values);
    }
  }

  Future<void> _rewritePlannedSets(
      int plannedExerciseId, List<PlannedSetValues> values) {
    return transaction(() async {
      await (delete(plannedSets)
            ..where((ps) => ps.plannedExerciseId.equals(plannedExerciseId)))
          .go();
      for (final sv in values) {
        await into(plannedSets).insert(PlannedSetsCompanion(
          plannedExerciseId: Value(plannedExerciseId),
          reps: Value(sv.reps),
          weight: Value(sv.weight),
          time: Value(sv.time),
        ));
      }
    });
  }

  /// Walks backward through prior weeks to find the most recent completed set
  /// data for [movementId] at [workoutOrderIndex]. Returns null if no history
  /// found (exercise was always skipped or never appeared).
  Future<({List<CompletedSet> nonSkipped, int totalCount})?> _findPriorSets(
    int movementId,
    int workoutOrderIndex,
    Week currentWeek,
    List<Week> allWeeks,
  ) async {
    for (var wn = currentWeek.weekNumber - 1; wn >= 1; wn--) {
      final priorWeek =
          allWeeks.firstWhere((w) => w.weekNumber == wn);

      final priorWorkout = await (select(workouts)
            ..where((w) =>
                w.weekId.equals(priorWeek.id) &
                w.orderIndex.equals(workoutOrderIndex)))
          .getSingleOrNull();
      if (priorWorkout == null || priorWorkout.isRestDay) continue;

      final priorCompleted = await (select(completedWorkouts)
            ..where((cw) => cw.workoutId.equals(priorWorkout.id)))
          .getSingleOrNull();
      if (priorCompleted == null) continue;

      final priorEx = await (select(completedExercises)
            ..where((ce) =>
                ce.completedWorkoutId.equals(priorCompleted.id) &
                ce.movementId.equals(movementId) &
                ce.persistence.equals(Persistence.dropped.index).not())
            ..orderBy([(ce) => OrderingTerm.desc(ce.id)])
            ..limit(1))
          .getSingleOrNull();
      if (priorEx == null || priorEx.skipReason != null) continue;

      final allSets = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(priorEx.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      final nonSkipped = allSets.where((s) => s.skipReason == null).toList();
      return (nonSkipped: nonSkipped, totalCount: allSets.length);
    }
    return null;
  }

  /// Re-runs AI recommendations for all autoProgress exercises in a planned
  /// workout using a single batched AI call. Only updates planned sets.
  /// Returns the number of exercises that were successfully re-planned with AI.
  Future<int> retryAiForPlannedWorkout(int workoutId) async {
    _lastAiErrors.clear();

    final pw = await (select(plannedWorkouts)
          ..where((p) => p.workoutId.equals(workoutId)))
        .getSingleOrNull();
    if (pw == null) return 0;

    final workout = await (select(workouts)
          ..where((w) => w.id.equals(workoutId)))
        .getSingle();
    final week = await (select(weeks)
          ..where((w) => w.id.equals(workout.weekId)))
        .getSingle();
    final allWeeksList = await (select(weeks)
          ..where((w) => w.mesocycleId.equals(week.mesocycleId))
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();

    final pes = await (select(plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(pw.id)))
        .get();

    final seeds = <_PlanSeed>[];
    for (final pe in pes) {
      if (!pe.autoProgress) continue;

      final movement = await (select(movements)
            ..where((m) => m.id.equals(pe.movementId)))
          .getSingle();
      final prior = await _findPriorSets(
          pe.movementId, workout.orderIndex, week, allWeeksList);
      if (prior == null) continue;

      seeds.add(_PlanSeed(
        plannedExerciseId: pe.id,
        movement: movement,
        priorSets: prior.nonSkipped,
        targetCount: prior.totalCount,
      ));
    }

    if (seeds.isEmpty) return 0;

    final results = await computeBatchRecommendation(
      exercises: [
        for (final s in seeds)
          BatchExerciseInput(
            movement: s.movement,
            priorSets: s.priorSets,
            targetCount: s.targetCount,
          ),
      ],
      weekGoal: week.goal,
      mesocycleId: week.mesocycleId,
      weekNumber: week.weekNumber,
      workoutName: workout.name,
      workoutId: workoutId,
    );

    var successCount = 0;
    for (var i = 0; i < seeds.length; i++) {
      final result = results[i];
      if (!result.usedAi) {
        if (result.error != null) _lastAiErrors.add(result.error!);
        continue;
      }
      await _rewritePlannedSets(seeds[i].plannedExerciseId, result.values);
      successCount++;
    }
    return successCount;
  }

  /// Runs a single AI call to refine planned sets for one newly-added
  /// exercise. Uses prior-mesocycle history if available. No-op if AI is
  /// disabled, the exercise doesn't opt into autoProgress, or no history
  /// exists. Safe to call after [addExerciseAfter] — the caller should
  /// refresh its view when this resolves.
  Future<void> refineAiForAddedExercise(
      int completedWorkoutId, int movementId) async {
    final cw = await (select(completedWorkouts)
          ..where((w) => w.id.equals(completedWorkoutId)))
        .getSingle();
    final pw = await (select(plannedWorkouts)
          ..where((p) => p.workoutId.equals(cw.workoutId)))
        .getSingleOrNull();
    if (pw == null) return;

    final pe = await (select(plannedExercises)
          ..where((p) =>
              p.plannedWorkoutId.equals(pw.id) &
              p.movementId.equals(movementId))
          ..orderBy([(p) => OrderingTerm.desc(p.id)])
          ..limit(1))
        .getSingleOrNull();
    if (pe == null || !pe.autoProgress) return;

    final workout = await (select(workouts)
          ..where((w) => w.id.equals(cw.workoutId)))
        .getSingle();
    final week = await (select(weeks)
          ..where((w) => w.id.equals(workout.weekId)))
        .getSingle();
    final movement = await (select(movements)
          ..where((m) => m.id.equals(movementId)))
        .getSingle();

    final priorSets =
        await _findHistoricalCompletedSets(movementId, week.mesocycleId);
    if (priorSets == null || priorSets.isEmpty) return;

    final result = await computeAiRecommendation(
      priorSets: priorSets,
      weekGoal: week.goal,
      movement: movement,
      targetCount: priorSets.length,
      mesocycleId: week.mesocycleId,
      weekNumber: week.weekNumber,
      workoutName: workout.name,
      workoutId: workout.id,
      autoProgress: true,
    );

    if (!result.usedAi) {
      if (result.error != null) _lastAiErrors.add(result.error!);
      return;
    }
    await _rewritePlannedSets(pe.id, result.values);
  }

  /// Public wrapper for [_resolveHistoricalSets] — returns sensible default
  /// set values for a movement based on prior-meso history.
  Future<List<PlannedSetValues>> getHistoricalSetDefaults(
    int movementId,
    int currentMesocycleId,
    Movement movement,
  ) =>
      _resolveHistoricalSets(movementId, currentMesocycleId, movement);

  /// Searches completed prior mesos for historical set data for [movementId].
  /// Uses the 2nd hard-week occurrence (or 1st if only one) from the most
  /// recent completed meso where the movement was performed.
  /// Falls back to cold start (2 null sets) if no history exists.
  Future<List<PlannedSetValues>> _resolveHistoricalSets(
    int movementId,
    int currentMesocycleId,
    Movement movement,
  ) async {
    final sets =
        await _findHistoricalCompletedSets(movementId, currentMesocycleId);
    if (sets == null) {
      return [const PlannedSetValues(), const PlannedSetValues()];
    }
    return sets
        .map((s) => PlannedSetValues(
              reps: s.reps,
              weight: s.weight,
              time: s.time,
            ))
        .toList();
  }

  /// Raw-CompletedSet version of [_resolveHistoricalSets]. Returns null if no
  /// usable prior-meso history for [movementId] exists.
  Future<List<CompletedSet>?> _findHistoricalCompletedSets(
      int movementId, int currentMesocycleId) async {
    final priorMesos = await (select(mesocycles)
          ..where((m) => m.id.isNotValue(currentMesocycleId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();

    for (final meso in priorMesos) {
      final rows = await (select(completedExercises).join([
        innerJoin(completedWorkouts, completedWorkouts.id
            .equalsExp(completedExercises.completedWorkoutId)),
        innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
        innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
      ])
            ..where(completedExercises.movementId.equals(movementId) &
                completedExercises.skipReason.isNull() &
                weeks.mesocycleId.equals(meso.id) &
                weeks.goal.equalsValue(WeekGoal.hard))
            ..orderBy([OrderingTerm.asc(weeks.weekNumber)]))
          .get();

      if (rows.isEmpty) continue;

      final byWeek = <int, CompletedExercise>{};
      for (final row in rows) {
        final wn = row.readTable(weeks).weekNumber;
        byWeek.putIfAbsent(wn, () => row.readTable(completedExercises));
      }
      final sortedWeeks = byWeek.keys.toList()..sort();
      final targetWeek =
          sortedWeeks.length >= 2 ? sortedWeeks[1] : sortedWeeks[0];
      final refExercise = byWeek[targetWeek]!;

      final sets = await (select(completedSets)
            ..where((s) =>
                s.completedExerciseId.equals(refExercise.id) &
                s.skipReason.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      if (sets.isEmpty) continue;
      return sets;
    }
    return null;
  }

  /// Idempotent — if a CompletedWorkout already exists for this workoutId
  /// (e.g. a prior call seeded exercises/sets before the caller crashed or
  /// navigated away), returns the existing id and skips re-seeding.
  Future<int> initializeWorkout(int workoutId) async {
    return await transaction(() async {
      final existing = await (select(completedWorkouts)
            ..where((w) => w.workoutId.equals(workoutId)))
          .getSingleOrNull();
      if (existing != null) return existing.id;

      final completedWorkoutId =
          await into(completedWorkouts).insert(CompletedWorkoutsCompanion.insert(
        workoutId: workoutId,
        startedAt: DateTime.now(),
        status: WorkoutStatus.active,
      ));

      final plannedWorkout = await (select(plannedWorkouts)
            ..where((pw) => pw.workoutId.equals(workoutId)))
          .getSingle();

      final plannedExs = await (select(plannedExercises)
            ..where((pe) => pe.plannedWorkoutId.equals(plannedWorkout.id))
            ..orderBy([(pe) => OrderingTerm.asc(pe.id)]))
          .get();

      for (var i = 0; i < plannedExs.length; i++) {
        final plannedEx = plannedExs[i];
        final completedExId =
            await into(completedExercises).insert(CompletedExercisesCompanion.insert(
          completedWorkoutId: completedWorkoutId,
          movementId: plannedEx.movementId,
          orderIndex: i,
          autoProgress: Value(plannedEx.autoProgress),
        ));

        final setsForEx = await (select(plannedSets)
              ..where((ps) => ps.plannedExerciseId.equals(plannedEx.id))
              ..orderBy([(ps) => OrderingTerm.asc(ps.id)]))
            .get();

        for (final _ in setsForEx) {
          await into(completedSets).insert(
              CompletedSetsCompanion.insert(completedExerciseId: completedExId));
        }
      }

      return completedWorkoutId;
    });
  }

  /// Idempotent — `workout_id` has a UNIQUE constraint, so a retry after a
  /// partial start-workout failure overwrites the prior checkin rather than
  /// raising a UNIQUE violation that would wedge the start flow.
  Future<void> savePreWorkoutCheckin(
          PreWorkoutCheckinsCompanion checkin) =>
      into(preWorkoutCheckins).insert(checkin, mode: InsertMode.replace);

  Future<PreWorkoutCheckin?> getPreWorkoutCheckin(int workoutId) =>
      (select(preWorkoutCheckins)
            ..where((c) => c.workoutId.equals(workoutId)))
          .getSingleOrNull();

  /// Returns the newest workout whose persisted row is still active.
  ///
  /// SharedPreferences only caches navigation IDs. This query is the recovery
  /// source of truth when those pointers are absent or stale after a restart.
  Future<ActiveWorkoutReference?> getActiveWorkoutReference() async {
    final row = await (select(completedWorkouts).join([
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
    ])
          ..where(completedWorkouts.status.equals(WorkoutStatus.active.name) &
              completedWorkouts.completedAt.isNull())
          ..orderBy([
            OrderingTerm.desc(completedWorkouts.startedAt),
            OrderingTerm.desc(completedWorkouts.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final completed = row.readTable(completedWorkouts);
    final workout = row.readTable(workouts);
    return ActiveWorkoutReference(
      completedWorkoutId: completed.id,
      workoutId: workout.id,
      workoutName: workout.name,
      startedAt: completed.startedAt,
      mesocycleId: row.readTable(weeks).mesocycleId,
    );
  }

  /// Atomically removes one exact in-progress attempt so its planned workout
  /// can be started again. Completed workouts are never eligible.
  Future<void> resetActiveWorkout(int completedWorkoutId) async {
    await transaction(() async {
      final active = await (select(completedWorkouts)
            ..where((row) =>
                row.id.equals(completedWorkoutId) &
                row.status.equals(WorkoutStatus.active.name) &
                row.completedAt.isNull()))
          .getSingleOrNull();
      if (active == null) {
        throw StateError('The workout is no longer active.');
      }

      final exerciseIds = await (selectOnly(completedExercises)
            ..addColumns([completedExercises.id])
            ..where(completedExercises.completedWorkoutId
                .equals(completedWorkoutId)))
          .map((row) => row.read(completedExercises.id)!)
          .get();
      if (exerciseIds.isNotEmpty) {
        await (delete(postExerciseCheckins)
              ..where((row) => row.completedExerciseId.isIn(exerciseIds)))
            .go();
        await (delete(completedSets)
              ..where((row) => row.completedExerciseId.isIn(exerciseIds)))
            .go();
      }
      await (delete(completedExercises)
            ..where((row) =>
                row.completedWorkoutId.equals(completedWorkoutId)))
          .go();
      await (delete(postMuscleGroupCheckins)
            ..where((row) =>
                row.completedWorkoutId.equals(completedWorkoutId)))
          .go();
      await (delete(completedWorkouts)
            ..where((row) => row.id.equals(completedWorkoutId)))
          .go();
      await (delete(preWorkoutCheckins)
            ..where((row) => row.workoutId.equals(active.workoutId)))
          .go();
    });
  }

  Future<WorkoutData> getWorkoutData(int completedWorkoutId) =>
      _getWorkoutData(completedWorkoutId, classifyActiveDamage: false);

  Future<WorkoutData> getActiveWorkoutData(int completedWorkoutId) =>
      _getWorkoutData(completedWorkoutId, classifyActiveDamage: true);

  Future<WorkoutData> _getWorkoutData(
    int completedWorkoutId, {
    required bool classifyActiveDamage,
  }) async {
    final cw = await (select(completedWorkouts)
          ..where((w) => w.id.equals(completedWorkoutId)))
        .getSingle();
    final workout = await (select(workouts)
          ..where((w) => w.id.equals(cw.workoutId)))
        .getSingle();

    final plannedWorkout = await (select(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(cw.workoutId)))
        .getSingleOrNull();
    if (classifyActiveDamage &&
        cw.status == WorkoutStatus.active &&
        cw.completedAt == null &&
        plannedWorkout == null) {
      // Starting this same scheduled workout calls generatePlannedWorkout
      // before initializeWorkout, so a wholly missing plan can be rebuilt.
      throw const WorkoutDataIntegrityException.resettable();
    }

    Future<T> requireIntactAttemptData<T>(Future<T> read) async {
      try {
        return await read;
      } on StateError {
        if (classifyActiveDamage &&
            cw.status == WorkoutStatus.active &&
            cw.completedAt == null) {
          throw const WorkoutDataIntegrityException.resettable();
        }
        rethrow;
      }
    }

    final completedExs = await (select(completedExercises)
          ..where((e) =>
              e.completedWorkoutId.equals(completedWorkoutId) &
              e.persistence.equals(Persistence.dropped.index).not())
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();

    if (classifyActiveDamage &&
        cw.status == WorkoutStatus.active &&
        cw.completedAt == null &&
        plannedWorkout != null) {
      final plannedExs = await (select(plannedExercises)
            ..where((exercise) =>
                exercise.plannedWorkoutId.equals(plannedWorkout.id)))
          .get();
      // Deliberately no persistence filter: intentionally removed exercises
      // remain as dropped rows and satisfy the planned-to-attempt link below.
      final attemptExsIncludingDropped = await (select(completedExercises)
            ..where((exercise) =>
                exercise.completedWorkoutId.equals(completedWorkoutId)))
          .get();
      final visibleMovementIds = <int>{};
      final visibleOrderIndexes = <int>{};
      for (final completed in completedExs) {
        final duplicateMovement =
            !visibleMovementIds.add(completed.movementId);
        final duplicateOrder =
            !visibleOrderIndexes.add(completed.orderIndex);
        if (duplicateMovement || duplicateOrder) {
          throw const WorkoutDataIntegrityException.resettable();
        }
      }
      for (final planned in plannedExs) {
        final hasAttemptRow = attemptExsIncludingDropped.any(
          (completed) => completed.movementId == planned.movementId,
        );
        if (!hasAttemptRow) {
          // A physically missing parent may have untraceable orphaned children,
          // so deleting this attempt cannot promise complete cleanup.
          throw const WorkoutDataIntegrityException.notResettable();
        }
      }
    }

    // No visible exercises remains valid when the plan was deliberately empty
    // or every exercise has an existing row marked as dropped.
    final exerciseDataList = <ExerciseData>[];
    for (final ce in completedExs) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(ce.movementId)))
          .getSingleOrNull();
      if (movement == null) {
        if (!classifyActiveDamage ||
            cw.status != WorkoutStatus.active ||
            cw.completedAt != null) {
          throw StateError('The workout references a missing movement.');
        }
        if (plannedWorkout == null) {
          throw const WorkoutDataIntegrityException.resettable();
        }
        final plannedReference = await (select(plannedExercises)
              ..where((exercise) =>
                  exercise.plannedWorkoutId.equals(plannedWorkout.id) &
                  exercise.movementId.equals(ce.movementId))
              ..limit(1))
            .getSingleOrNull();
        if (plannedReference != null) {
          throw const WorkoutDataIntegrityException.notResettable();
        }
        throw const WorkoutDataIntegrityException.resettable();
      }

      // Zero completed-set rows is valid: the user may intentionally delete
      // every prescribed set while keeping the exercise in the workout.
      final completedSetsForEx = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(ce.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      List<PlannedSet> plannedSetsForEx = [];
      if (plannedWorkout != null) {
        final plannedEx = await (select(plannedExercises)
              ..where((pe) =>
                  pe.plannedWorkoutId.equals(plannedWorkout.id) &
                  pe.movementId.equals(ce.movementId)))
            .getSingleOrNull();
        if (plannedEx != null) {
          plannedSetsForEx = await (select(plannedSets)
                ..where((ps) => ps.plannedExerciseId.equals(plannedEx.id))
                ..orderBy([(ps) => OrderingTerm.asc(ps.id)]))
              .get();
        }
      }

      final sets = [
        for (var i = 0; i < completedSetsForEx.length; i++)
          SetData(
            completed: completedSetsForEx[i],
            planned: i < plannedSetsForEx.length ? plannedSetsForEx[i] : null,
          ),
      ];

      // Feedback is optional until the workout reaches that question. A null
      // row is valid; only duplicate one-to-one rows indicate attempt damage.
      final postExCheckin = await requireIntactAttemptData(
        (select(postExerciseCheckins)
              ..where((c) => c.completedExerciseId.equals(ce.id)))
            .getSingleOrNull(),
      );

      exerciseDataList.add(ExerciseData(
        completed: ce,
        movement: movement,
        sets: sets,
        postExerciseCheckin: postExCheckin,
      ));
    }

    // Muscle-group feedback is also optional until it is answered.
    final mgCheckins = await (select(postMuscleGroupCheckins)
          ..where((c) => c.completedWorkoutId.equals(completedWorkoutId)))
        .get();

    return WorkoutData(
      completedWorkout: cw,
      workout: workout,
      exercises: exerciseDataList,
      postMuscleGroupCheckins: mgCheckins,
    );
  }

  Future<void> saveCompletedSet(
      int id, {
      int? reps,
      double? weight,
      double? distance,
      double? time,
  }) async {
    if (reps != null && reps < 1) {
      throw ArgumentError.value(reps, 'reps', 'must be greater than 0');
    }
    if (weight != null && !weight.isFinite) {
      throw ArgumentError.value(weight, 'weight', 'must be finite');
    }
    if (distance != null && (!distance.isFinite || distance <= 0)) {
      throw ArgumentError.value(
        distance,
        'distance',
        'must be finite and greater than 0',
      );
    }
    if (time != null && (!time.isFinite || time <= 0)) {
      throw ArgumentError.value(
        time,
        'time',
        'must be finite and greater than 0',
      );
    }
    await (update(completedSets)..where((s) => s.id.equals(id))).write(
      CompletedSetsCompanion(
        reps: Value(reps),
        weight: Value(weight),
        distance: Value(distance),
        time: Value(time),
      ),
    );
  }

  Future<void> skipSet(int id, SkipReason reason) =>
      (update(completedSets)..where((s) => s.id.equals(id))).write(
        CompletedSetsCompanion(
          skipReason: Value(reason),
          reps: const Value(null),
          weight: const Value(null),
          distance: const Value(null),
          time: const Value(null),
        ),
      );

  Future<void> clearCompletedSet(int id) =>
      (update(completedSets)..where((s) => s.id.equals(id))).write(
        const CompletedSetsCompanion(
          reps: Value(null),
          weight: Value(null),
          distance: Value(null),
          time: Value(null),
          skipReason: Value(null),
        ),
      );

  Future<void> skipExercise(int completedExerciseId, SkipReason reason) async {
    await transaction(() async {
      await (update(completedExercises)
            ..where((e) => e.id.equals(completedExerciseId)))
          .write(CompletedExercisesCompanion(skipReason: Value(reason)));
      final sets = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(completedExerciseId)))
          .get();
      for (final s in sets) {
        await skipSet(s.id, reason);
      }
    });
  }

  Future<void> unskipExercise(int completedExerciseId) async {
    await transaction(() async {
      await (update(completedExercises)
            ..where((e) => e.id.equals(completedExerciseId)))
          .write(const CompletedExercisesCompanion(skipReason: Value(null)));
      final sets = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(completedExerciseId)))
          .get();
      for (final s in sets) {
        await clearCompletedSet(s.id);
      }
    });
  }

  Future<void> clearPostExerciseCheckin(int completedExerciseId) =>
      (delete(postExerciseCheckins)
            ..where((c) => c.completedExerciseId.equals(completedExerciseId)))
          .go();

  Future<void> clearPostMuscleGroupCheckin(
          int completedWorkoutId, MuscleGroup muscleGroup) =>
      (delete(postMuscleGroupCheckins)
            ..where((c) =>
                c.completedWorkoutId.equals(completedWorkoutId) &
                c.muscleGroup.equals(muscleGroup.name)))
          .go();

  Future<void> savePostExerciseCheckin(
          PostExerciseCheckinsCompanion checkin) =>
      into(postExerciseCheckins).insert(checkin);

  Future<void> savePostMuscleGroupCheckin(
          PostMuscleGroupCheckinsCompanion checkin) =>
      into(postMuscleGroupCheckins).insert(checkin);

  Future<int> addSet(int completedExerciseId) =>
      into(completedSets).insert(
        CompletedSetsCompanion.insert(completedExerciseId: completedExerciseId));

  Future<void> deleteSet(int completedSetId) =>
      (delete(completedSets)..where((s) => s.id.equals(completedSetId))).go();

  // ── Meso template methods ───────────────────────────────────────────────────

  Future<List<MesoTemplate>> getMesoTemplates() =>
      (select(mesoTemplates)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  /// Returns all templates with their associated mesocycle history.
  Future<List<MesoTemplateWithHistory>> getMesoTemplatesWithHistory() async {
    final templates = await (select(mesoTemplates)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    final result = <MesoTemplateWithHistory>[];
    for (final t in templates) {
      final past = await (select(mesocycles)
            ..where((m) => m.mesoTemplateId.equals(t.id))
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .get();
      result.add(MesoTemplateWithHistory(template: t, pastMesos: past));
    }
    return result;
  }

  Future<MesoTemplateData> getMesoTemplateData(int mesoTemplateId) async {
    final template = await (select(mesoTemplates)
          ..where((t) => t.id.equals(mesoTemplateId)))
        .getSingle();

    final wts = await (select(workoutTemplates).join([
      innerJoin(weekTemplates, weekTemplates.id.equalsExp(workoutTemplates.weekTemplateId)),
    ])
          ..where(weekTemplates.mesoTemplateId.equals(mesoTemplateId))
          ..orderBy([OrderingTerm.asc(workoutTemplates.dayIndex)]))
        .map((row) => row.readTable(workoutTemplates))
        .get();

    final days = <WorkoutDayData>[];
    for (final wt in wts) {
      final exTemplates = await (select(exerciseTemplates)
            ..where((et) => et.workoutTemplateId.equals(wt.id))
            ..orderBy([(et) => OrderingTerm.asc(et.exerciseIndex)]))
          .get();

      final entries = <ExerciseDayEntry>[];
      for (final et in exTemplates) {
        final m = await (select(movements)..where((m) => m.id.equals(et.movementId))).getSingle();
        entries.add(ExerciseDayEntry(movement: m, autoProgress: et.autoProgress));
      }
      days.add(WorkoutDayData(template: wt, exercises: entries));
    }

    return MesoTemplateData(template: template, days: days);
  }

  Future<int> createMesoTemplate(String name, List<WorkoutDaySpec> days) async {
    return await transaction(() async {
      final mesoTemplateId = await into(mesoTemplates).insert(
        MesoTemplatesCompanion.insert(
          name: name,
          createdAt: Value(DateTime.now()),
        ),
      );
      await _insertTemplateStructure(mesoTemplateId, days);
      return mesoTemplateId;
    });
  }

  Future<void> updateMesoTemplate(
      int id, String name, List<WorkoutDaySpec> days) async {
    await transaction(() async {
      await (update(mesoTemplates)..where((t) => t.id.equals(id)))
          .write(MesoTemplatesCompanion(name: Value(name)));

      final oldWeekTemplates = await (select(weekTemplates)
            ..where((wt) => wt.mesoTemplateId.equals(id)))
          .get();
      for (final wt in oldWeekTemplates) {
        final oldWorkoutTemplates = await (select(workoutTemplates)
              ..where((t) => t.weekTemplateId.equals(wt.id)))
            .get();
        for (final owt in oldWorkoutTemplates) {
          await (delete(exerciseTemplates)
                ..where((et) => et.workoutTemplateId.equals(owt.id)))
              .go();
        }
        await (delete(workoutTemplates)
              ..where((t) => t.weekTemplateId.equals(wt.id)))
            .go();
        await (delete(weekTemplates)..where((t) => t.id.equals(wt.id))).go();
      }

      await _insertTemplateStructure(id, days);
    });
  }

  /// Throws [TemplateInUseException] if any active mesocycle uses this template.
  /// [currentMesocycleId] should come from AppPreferences.getCurrentMesocycleId().
  Future<void> deleteMesoTemplate(int id, {int? currentMesocycleId}) async {
    if (currentMesocycleId != null) {
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(currentMesocycleId)))
          .getSingleOrNull();
      if (meso != null && meso.mesoTemplateId == id) {
        throw TemplateInUseException();
      }
    }

    await transaction(() async {
      final wts = await (select(weekTemplates)
            ..where((wt) => wt.mesoTemplateId.equals(id)))
          .get();
      for (final wt in wts) {
        final owts = await (select(workoutTemplates)
              ..where((t) => t.weekTemplateId.equals(wt.id)))
            .get();
        for (final owt in owts) {
          await (delete(exerciseTemplates)
                ..where((et) => et.workoutTemplateId.equals(owt.id)))
              .go();
        }
        await (delete(workoutTemplates)
              ..where((t) => t.weekTemplateId.equals(wt.id)))
            .go();
        await (delete(weekTemplates)..where((t) => t.id.equals(wt.id))).go();
      }
      await (delete(mesoTemplates)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> _insertTemplateStructure(
      int mesoTemplateId, List<WorkoutDaySpec> days) async {
    final weekTemplateId = await into(weekTemplates).insert(
      WeekTemplatesCompanion.insert(
        mesoTemplateId: mesoTemplateId,
        name: 'Week',
        workoutCount: days.where((d) => !d.isRestDay).length,
      ),
    );

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final workoutTemplateId = await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          weekTemplateId: weekTemplateId,
          name: day.name,
          isRestDay: day.isRestDay,
          dayIndex: i,
        ),
      );

      for (var j = 0; j < day.exercises.length; j++) {
        final ex = day.exercises[j];
        await into(exerciseTemplates).insert(
          ExerciseTemplatesCompanion.insert(
            workoutTemplateId: workoutTemplateId,
            movementId: ex.movementId,
            exerciseIndex: j,
            autoProgress: Value(ex.autoProgress),
          ),
        );
      }
    }
  }

  // ── Past-mesocycle → template methods ─────────────────────────────────────

  /// Returns completed mesocycles and their fully completed weeks. Naturally
  /// completed legacy rows with a missing completedAt value are repaired.
  Future<List<MesocycleWeekSummary>> getMesocyclesWithCompletedWeeks() async {
    final allMesos = await (select(mesocycles)
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();

    final result = <MesocycleWeekSummary>[];
    for (var meso in allMesos) {
      final mesoWeeks = await (select(weeks)
            ..where((w) => w.mesocycleId.equals(meso.id))
            ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
          .get();

      final weekSummaries = <WeekSummary>[];
      for (final week in mesoWeeks) {
        final summary = await _completedWeekSummary(week, mesoWeeks);
        if (summary != null) weekSummaries.add(summary);
      }

      final naturallyComplete = mesoWeeks.isNotEmpty &&
          mesoWeeks.last.weekNumber >= meso.totalWeekCount &&
          weekSummaries.any((s) => s.week.id == mesoWeeks.last.id);
      if (meso.completedAt == null && naturallyComplete) {
        final completedAt = await _lastCompletedDate(meso.id) ?? DateTime.now();
        await (update(mesocycles)..where((m) => m.id.equals(meso.id)))
            .write(MesocyclesCompanion(completedAt: Value(completedAt)));
        meso = meso.copyWith(completedAt: Value(completedAt));
      }

      if (meso.completedAt != null && weekSummaries.isNotEmpty) {
        result.add(MesocycleWeekSummary(
          mesocycle: meso,
          weeks: weekSummaries,
        ));
      }
    }
    return result;
  }

  Future<WeekSummary?> _completedWeekSummary(
      Week week, List<Week> mesoWeeks) async {
    final expectedCount = (await _getWeekTemplateSlots(week, mesoWeeks))
        .where((slot) => !slot.isRestDay)
        .length;
    final weekWorkouts = await (select(workouts)
          ..where((w) => w.weekId.equals(week.id) & w.isRestDay.equals(false)))
        .get();
    var completedCount = 0;
    for (final workout in weekWorkouts) {
      final completed = await (select(completedWorkouts)
            ..where((row) =>
                row.workoutId.equals(workout.id) & row.completedAt.isNotNull()))
          .getSingleOrNull();
      if (completed != null) completedCount++;
    }
    if (expectedCount == 0 || completedCount != expectedCount) return null;
    return WeekSummary(
      week: week,
      completedWorkoutCount: completedCount,
      totalWorkoutCount: expectedCount,
    );
  }

  Future<void> _markMesocycleCompleteIfFinished(int mesocycleId) async {
    final meso = await (select(mesocycles)
          ..where((row) => row.id.equals(mesocycleId)))
        .getSingle();
    if (meso.completedAt != null) return;
    final mesoWeeks = await (select(weeks)
          ..where((row) => row.mesocycleId.equals(mesocycleId))
          ..orderBy([(row) => OrderingTerm.asc(row.weekNumber)]))
        .get();
    if (mesoWeeks.isEmpty ||
        mesoWeeks.last.weekNumber < meso.totalWeekCount ||
        await _completedWeekSummary(mesoWeeks.last, mesoWeeks) == null) {
      return;
    }
    final completedAt = await _lastCompletedDate(mesocycleId) ?? DateTime.now();
    await (update(mesocycles)..where((row) => row.id.equals(mesocycleId)))
        .write(MesocyclesCompanion(completedAt: Value(completedAt)));
  }

  /// Extracts a completed week's exercise lineup and returns it together with
  /// the currently stored template associated with its mesocycle.
  Future<PastWeekTemplateData> getMesoTemplateDataFromWeek(int weekId) async {
    final week =
        await (select(weeks)..where((w) => w.id.equals(weekId))).getSingle();
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(week.mesocycleId)))
        .getSingle();

    final mesoWeeks = await (select(weeks)
          ..where((row) => row.mesocycleId.equals(meso.id))
          ..orderBy([(row) => OrderingTerm.asc(row.weekNumber)]))
        .get();
    final weekSlots = await _getWeekTemplateSlots(week, mesoWeeks);

    final weekWorkouts = await (select(workouts)
          ..where((w) => w.weekId.equals(weekId))
          ..orderBy([(w) => OrderingTerm.asc(w.orderIndex)]))
        .get();
    final workoutByOrder = {
      for (final workout in weekWorkouts) workout.orderIndex: workout,
    };

    final days = <WorkoutDayData>[];
    for (final slot in weekSlots) {
      final workout = workoutByOrder[slot.orderIndex];
      final exercises = <ExerciseDayEntry>[];

      if (!slot.isRestDay && workout != null) {
        final completed = await (select(completedWorkouts)
              ..where((cw) => cw.workoutId.equals(workout.id)))
            .getSingleOrNull();

        if (completed != null) {
          // Only persistent exercises — same filter as _seedFromPriorWeeks.
          final cExercises = await (select(completedExercises)
                ..where((ce) =>
                    ce.completedWorkoutId.equals(completed.id) &
                    ce.persistence.equals(Persistence.persistent.index))
                ..orderBy([(ce) => OrderingTerm.asc(ce.orderIndex)]))
              .get();

          for (final ce in cExercises) {
            final movement = await (select(movements)
                  ..where((m) => m.id.equals(ce.movementId)))
                .getSingle();
            exercises.add(ExerciseDayEntry(
              movement: movement,
              autoProgress: ce.autoProgress,
            ));
          }
        }
      }

      days.add(WorkoutDayData(
        template: WorkoutTemplate(
          id: -1,
          weekTemplateId: -1,
          name: slot.name,
          isRestDay: slot.isRestDay,
          dayIndex: slot.orderIndex,
        ),
        exercises: exercises,
      ));
    }

    final extracted = MesoTemplateData(
      template: MesoTemplate(
        id: -1,
        name: 'From ${meso.name} W${week.weekNumber}',
        createdAt: DateTime.now(),
      ),
      days: days,
    );

    return PastWeekTemplateData(
      mesocycle: meso,
      week: week,
      weekData: extracted,
      associatedTemplate: await getMesoTemplateData(meso.mesoTemplateId),
    );
  }

  Future<bool> mesoTemplateMatches(
    int templateId,
    List<WorkoutDaySpec> days, {
    String? name,
  }) async {
    final source = await getMesoTemplateData(templateId);
    if (name != null && source.template.name != name) return false;
    final sourceDays = workoutDaySpecsFromData(source);
    if (sourceDays.length != days.length) return false;
    for (var dayIndex = 0; dayIndex < sourceDays.length; dayIndex++) {
      final sourceDay = sourceDays[dayIndex];
      final candidateDay = days[dayIndex];
      if (sourceDay.name != candidateDay.name ||
          sourceDay.isRestDay != candidateDay.isRestDay ||
          sourceDay.exercises.length != candidateDay.exercises.length) {
        return false;
      }
      for (var exerciseIndex = 0;
          exerciseIndex < sourceDay.exercises.length;
          exerciseIndex++) {
        final sourceExercise = sourceDay.exercises[exerciseIndex];
        final candidateExercise = candidateDay.exercises[exerciseIndex];
        if (sourceExercise.movementId != candidateExercise.movementId ||
            sourceExercise.autoProgress != candidateExercise.autoProgress) {
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> mesoTemplateNameExists(String name, {int? excludingId}) async {
    final normalized = name.toLowerCase();
    final templates = await select(mesoTemplates).get();
    return templates.any((template) =>
        template.id != excludingId && template.name.toLowerCase() == normalized);
  }

  Future<List<Movement>> getMovements() =>
      (select(movements)
        ..orderBy([
          (m) => OrderingTerm.asc(m.muscleGroup),
          (m) => OrderingTerm.asc(m.name),
        ]))
          .get();

  void _validateMovementNumbers(MovementsCompanion companion) {
    final minWeight = companion.minWeight;
    if (minWeight.present &&
        minWeight.value != null &&
        !minWeight.value!.isFinite) {
      throw ArgumentError.value(
        minWeight.value,
        'minWeight',
        'must be finite',
      );
    }

    final weightDelta = companion.weightDelta;
    if (weightDelta.present &&
        weightDelta.value != null &&
        (!weightDelta.value!.isFinite || weightDelta.value! <= 0)) {
      throw ArgumentError.value(
        weightDelta.value,
        'weightDelta',
        'must be finite and greater than 0',
      );
    }

    final bodyweightLoadFraction = companion.bodyweightLoadFraction;
    if (bodyweightLoadFraction.present &&
        (!bodyweightLoadFraction.value.isFinite ||
            bodyweightLoadFraction.value < 0 ||
            bodyweightLoadFraction.value > 1)) {
      throw ArgumentError.value(
        bodyweightLoadFraction.value,
        'bodyweightLoadFraction',
        'must be finite and between 0 and 1',
      );
    }

    final restSeconds = companion.restSeconds;
    if (restSeconds.present &&
        restSeconds.value != null &&
        restSeconds.value! < 0) {
      throw ArgumentError.value(
        restSeconds.value,
        'restSeconds',
        'must be 0 or greater',
      );
    }
  }

  Future<Movement> createMovement(MovementsCompanion companion) {
    _validateMovementNumbers(companion);
    return into(movements).insertReturning(companion);
  }

  Future<void> updateMovement(MovementsCompanion companion) {
    _validateMovementNumbers(companion);
    return (update(movements)..where((m) => m.id.equals(companion.id.value)))
        .write(companion);
  }

  /// Marks the workout complete in the DB.
  /// Caller is responsible for clearing AppPreferences.currentCompletedWorkoutId.
  Future<void> finishWorkout(int completedWorkoutId) async {
    await (update(completedWorkouts)
          ..where((w) => w.id.equals(completedWorkoutId)))
        .write(CompletedWorkoutsCompanion(
        completedAt: Value(DateTime.now()),
        status: const Value(WorkoutStatus.completed),
      ));
    final completed = await (select(completedWorkouts)
          ..where((row) => row.id.equals(completedWorkoutId)))
        .getSingle();
    final workout = await (select(workouts)
          ..where((row) => row.id.equals(completed.workoutId)))
        .getSingle();
    final week = await (select(weeks)
          ..where((row) => row.id.equals(workout.weekId)))
        .getSingle();
    await _markMesocycleCompleteIfFinished(week.mesocycleId);
  }

  Future<void> skipWorkout(int workoutId, WorkoutSkipReason reason) async {
    final now = DateTime.now();
    await into(completedWorkouts).insert(CompletedWorkoutsCompanion.insert(
      workoutId: workoutId,
      startedAt: now,
      completedAt: Value(now),
      status: WorkoutStatus.skipped,
      skipReason: Value(reason),
    ));
    final workout = await (select(workouts)
          ..where((row) => row.id.equals(workoutId)))
        .getSingle();
    final week = await (select(weeks)
          ..where((row) => row.id.equals(workout.weekId)))
        .getSingle();
    await _markMesocycleCompleteIfFinished(week.mesocycleId);
  }

  Future<void> setPersistence(
          int completedExerciseId, Persistence persistence) =>
      (update(completedExercises)
            ..where((e) => e.id.equals(completedExerciseId)))
          .write(CompletedExercisesCompanion(persistence: Value(persistence)));

  /// Toggles the auto-progress flag for an exercise instance, and propagates
  /// the change up through [PlannedExercises] and [ExerciseTemplates] so all
  /// future weeks inherit the setting automatically.
  Future<void> setExerciseAutoProgress(
      int completedExerciseId, bool autoProgress) async {
    // 1. Update the current CompletedExercise.
    final ex = await (select(completedExercises)
          ..where((e) => e.id.equals(completedExerciseId)))
        .getSingle();

    await (update(completedExercises)
          ..where((e) => e.id.equals(completedExerciseId)))
        .write(CompletedExercisesCompanion(autoProgress: Value(autoProgress)));

    // 2. Update the matching PlannedExercise (for _seedFromPriorWeeks).
    final cw = await (select(completedWorkouts)
          ..where((w) => w.id.equals(ex.completedWorkoutId)))
        .getSingle();

    final pw = await (select(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(cw.workoutId)))
        .getSingleOrNull();

    if (pw != null) {
      await (update(plannedExercises)
            ..where((pe) =>
                pe.plannedWorkoutId.equals(pw.id) &
                pe.movementId.equals(ex.movementId)))
          .write(PlannedExercisesCompanion(autoProgress: Value(autoProgress)));

      // 3. Update the ExerciseTemplate (for _generateFromTemplate / week 1).
      final workout = await (select(workouts)
            ..where((w) => w.id.equals(cw.workoutId)))
          .getSingle();

      final wt = await (select(workoutTemplates).join([
        innerJoin(weekTemplates,
            weekTemplates.id.equalsExp(workoutTemplates.weekTemplateId)),
        innerJoin(mesocycles,
            mesocycles.mesoTemplateId.equalsExp(weekTemplates.mesoTemplateId)),
        innerJoin(
            weeks, weeks.mesocycleId.equalsExp(mesocycles.id)),
      ])
            ..where(weeks.id.equals(workout.weekId) &
                workoutTemplates.dayIndex.equals(workout.orderIndex))
            ..limit(1))
          .map((row) => row.readTable(workoutTemplates))
          .getSingleOrNull();

      if (wt != null) {
        await (update(exerciseTemplates)
              ..where((et) =>
                  et.workoutTemplateId.equals(wt.id) &
                  et.movementId.equals(ex.movementId)))
            .write(ExerciseTemplatesCompanion(autoProgress: Value(autoProgress)));
      }
    }
  }

  /// Adds an exercise after [afterOrderIndex]; use -1 for an empty workout.
  Future<void> addExerciseAfter(
    int completedWorkoutId,
    int afterOrderIndex,
    int movementId, {
    List<PlannedSetValues> defaults = const [
      PlannedSetValues(),
      PlannedSetValues(),
    ],
  }) =>
      transaction(() async {
        final completedWorkout = await (select(completedWorkouts)
              ..where((w) => w.id.equals(completedWorkoutId)))
            .getSingle();
        final plannedWorkout = await (select(plannedWorkouts)
              ..where((p) => p.workoutId.equals(completedWorkout.workoutId)))
            .getSingleOrNull();

        PlannedExercise? existingPlannedExercise;
        var setDefaults = defaults;
        if (plannedWorkout != null) {
          existingPlannedExercise = await (select(plannedExercises)
                ..where((exercise) =>
                    exercise.plannedWorkoutId.equals(plannedWorkout.id) &
                    exercise.movementId.equals(movementId))
                ..orderBy([(exercise) => OrderingTerm.asc(exercise.id)])
                ..limit(1))
              .getSingleOrNull();
          if (existingPlannedExercise != null) {
            final existingSets = await (select(plannedSets)
                  ..where((set) => set.plannedExerciseId
                      .equals(existingPlannedExercise!.id))
                  ..orderBy([(set) => OrderingTerm.asc(set.id)]))
                .get();
            if (existingSets.isNotEmpty) {
              setDefaults = [
                for (final set in existingSets)
                  PlannedSetValues(
                    reps: set.reps,
                    weight: set.weight,
                    time: set.time,
                  ),
              ];
            }
          }
        }

        await customUpdate(
          'UPDATE completed_exercises '
          'SET order_index = order_index + 1 '
          'WHERE completed_workout_id = ? AND order_index > ?',
          variables: [
            Variable.withInt(completedWorkoutId),
            Variable.withInt(afterOrderIndex),
          ],
          updates: {completedExercises},
        );
        final newExId = await into(completedExercises).insert(
          CompletedExercisesCompanion.insert(
            completedWorkoutId: completedWorkoutId,
            movementId: movementId,
            orderIndex: afterOrderIndex + 1,
            autoProgress: Value(existingPlannedExercise?.autoProgress ?? true),
          ),
        );

        // Create empty completed sets (user fills them in).
        for (final _ in setDefaults) {
          await into(completedSets).insert(
            CompletedSetsCompanion.insert(completedExerciseId: newExId),
          );
        }

        // Reuse an original planned exercise when one exists. Inserting a
        // duplicate for a movement that was deleted and re-added makes workout
        // loading ambiguous because completed rows resolve plans by movement.
        if (plannedWorkout != null && existingPlannedExercise == null) {
          final plannedExId = await into(plannedExercises).insert(
            PlannedExercisesCompanion.insert(
              plannedWorkoutId: plannedWorkout.id,
              movementId: movementId,
            ),
          );
          for (final sv in setDefaults) {
            await into(plannedSets).insert(
              PlannedSetsCompanion(
                plannedExerciseId: Value(plannedExId),
                reps: Value(sv.reps),
                weight: Value(sv.weight),
                time: Value(sv.time),
              ),
            );
          }
        }
        await _clearMuscleGroupCheckinForMovement(
          completedWorkoutId,
          movementId,
        );
      });

  Future<void> swapExerciseOrder(
    int idA,
    int orderIndexA,
    int idB,
    int orderIndexB,
  ) =>
      transaction(() async {
        await (update(completedExercises)..where((e) => e.id.equals(idA)))
            .write(CompletedExercisesCompanion(orderIndex: Value(orderIndexB)));
        await (update(completedExercises)..where((e) => e.id.equals(idB)))
            .write(CompletedExercisesCompanion(orderIndex: Value(orderIndexA)));
      });

  Future<void> deleteExercise(int completedExerciseId) =>
      (update(completedExercises)
            ..where((e) => e.id.equals(completedExerciseId)))
          .write(const CompletedExercisesCompanion(
              persistence: Value(Persistence.dropped)));

  Future<void> replaceExercise(
    int oldExId,
    int movementId,
    int orderIndex,
    int completedWorkoutId,
  ) =>
      transaction(() async {
        final oldExercise = await (select(completedExercises)
              ..where((exercise) =>
                  exercise.id.equals(oldExId) &
                  exercise.completedWorkoutId.equals(completedWorkoutId)))
            .getSingle();
        final sets = await (select(completedSets)
              ..where((set) => set.completedExerciseId.equals(oldExId)))
            .get();
        final feedback = await (select(postExerciseCheckins)
              ..where((checkin) =>
                  checkin.completedExerciseId.equals(oldExId)))
            .getSingleOrNull();
        final hasRecordedActivity =
            oldExercise.skipReason != null ||
            feedback != null ||
            sets.any((set) =>
                set.reps != null ||
                set.weight != null ||
                set.distance != null ||
                set.time != null ||
                set.skipReason != null);
        if (hasRecordedActivity) {
          throw const ExerciseReplacementBlockedException();
        }

        await (update(completedExercises)
              ..where((e) => e.id.equals(oldExId)))
            .write(CompletedExercisesCompanion(
                persistence: const Value(Persistence.dropped)));
        final newExId = await into(completedExercises).insert(
          CompletedExercisesCompanion.insert(
            completedWorkoutId: completedWorkoutId,
            movementId: movementId,
            orderIndex: orderIndex,
          ),
        );
        await into(completedSets).insert(
          CompletedSetsCompanion.insert(completedExerciseId: newExId),
        );
        await _clearMuscleGroupCheckinForMovement(
          completedWorkoutId,
          movementId,
        );
      });

  Future<void> _clearMuscleGroupCheckinForMovement(
    int completedWorkoutId,
    int movementId,
  ) async {
    final movement = await (select(movements)
          ..where((row) => row.id.equals(movementId)))
        .getSingle();
    await (delete(postMuscleGroupCheckins)
          ..where((checkin) =>
              checkin.completedWorkoutId.equals(completedWorkoutId) &
              checkin.muscleGroup.equals(movement.muscleGroup.name)))
        .go();
  }

  /// Returns mesocycle IDs that have at least one started non-rest workout.
  ///
  /// Includes active workouts so the History calendar can distinguish the
  /// current workout from completed and future workouts. Mesocycles are
  /// ordered by their most recently started workout, newest first.
  Future<List<int>> getMesocycleIdsWithWorkoutHistory() async {
    final rows = await (select(completedWorkouts).join([
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
    ])
          ..where(workouts.isRestDay.equals(false))
          ..orderBy([
            OrderingTerm.desc(completedWorkouts.startedAt),
            OrderingTerm.desc(completedWorkouts.id),
          ]))
        .get();

    final seen = <int>{};
    final ids = <int>[];
    for (final row in rows) {
      final id = row.readTable(weeks).mesocycleId;
      if (seen.add(id)) ids.add(id);
    }
    return ids;
  }

  /// Returns all non-rest-day completed workouts (excludes active/in-progress), newest first.
  Future<List<CompletedWorkoutSummary>> getCompletedWorkoutSummaries() async {
    final rows = await (select(completedWorkouts).join([
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
      innerJoin(mesocycles, mesocycles.id.equalsExp(weeks.mesocycleId)),
    ])
          ..where(workouts.isRestDay.equals(false) &
              completedWorkouts.completedAt.isNotNull())
          ..orderBy([OrderingTerm.desc(completedWorkouts.startedAt)]))
        .get();

    return rows.map((row) {
      return CompletedWorkoutSummary(
        completedWorkout: row.readTable(completedWorkouts),
        workoutName: row.readTable(workouts).name,
        weekNumber: row.readTable(weeks).weekNumber,
        mesoName: row.readTable(mesocycles).name,
        mesocycleId: row.readTable(mesocycles).id,
      );
    }).toList();
  }

  /// Returns all completed exercises for [movementId] (excludes active/in-progress), newest first.
  /// Only includes sessions where the exercise was actually present (done or skipped).
  Future<List<MovementHistoryEntry>> getMovementHistory(int movementId) async {
    final rows = await (select(completedExercises).join([
      innerJoin(completedWorkouts,
          completedWorkouts.id.equalsExp(completedExercises.completedWorkoutId)),
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
      innerJoin(mesocycles, mesocycles.id.equalsExp(weeks.mesocycleId)),
    ])
          ..where(completedExercises.movementId.equals(movementId) &
              completedWorkouts.completedAt.isNotNull())
          ..orderBy([OrderingTerm.desc(completedWorkouts.startedAt)]))
        .get();

    final result = <MovementHistoryEntry>[];
    for (final row in rows) {
      final exercise = row.readTable(completedExercises);
      final cw = row.readTable(completedWorkouts);
      final w = row.readTable(workouts);
      final week = row.readTable(weeks);
      final meso = row.readTable(mesocycles);

      final sets = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(exercise.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      result.add(MovementHistoryEntry(
        mesoId: meso.id,
        mesoName: meso.name,
        weekNumber: week.weekNumber,
        workoutName: w.name,
        workoutDate: cw.startedAt,
        exercise: exercise,
        sets: sets,
      ));
    }
    return result;
  }

  /// Returns the expected date for the next workout: the day after the most
  /// recently completed workout in this mesocycle. Falls back to today.
  Future<DateTime> getExpectedWorkoutDate(int mesocycleId) async {
    final last = await _lastCompletedDate(mesocycleId);
    if (last == null) return DateTime.now();
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay.add(const Duration(days: 1));
  }

  /// Returns the full mesocycle calendar — materialized weeks with actual data,
  /// plus template-based entries for future weeks not yet in the DB.
  Future<MesocycleCalendar> getMesocycleCalendar(int mesocycleId) async {
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(mesocycleId)))
        .getSingle();

    // ── Materialized weeks ───────────────────────────────────────────────────
    final weeksList = await (select(weeks)
          ..where((w) => w.mesocycleId.equals(mesocycleId))
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();

    final calendarWeeks = <CalendarWeek>[];
    for (final week in weeksList) {
      final workoutsList = await (select(workouts)
            ..where(
                (w) => w.weekId.equals(week.id) & w.isRestDay.equals(false))
            ..orderBy([(w) => OrderingTerm.asc(w.orderIndex)]))
          .get();

      final cells = <CalendarCell>[];
      for (final workout in workoutsList) {
        final cw = await (select(completedWorkouts)
              ..where((cw) => cw.workoutId.equals(workout.id)))
            .getSingleOrNull();
        cells.add(CalendarCell(
          workoutId: workout.id,
          workoutName: workout.name,
          orderIndex: workout.orderIndex,
          completedWorkout: cw,
        ));
      }
      calendarWeeks.add(CalendarWeek(
        weekNumber: week.weekNumber,
        goal: week.goal,
        cells: cells,
      ));
    }

    // ── Fill remaining slots in the last partially-materialized week ─────────
    if (weeksList.isNotEmpty) {
      final lastWeek = weeksList.last;
      final allSlots = await _getWeekTemplateSlots(lastWeek, weeksList);
      final trainingSlots = allSlots.where((s) => !s.isRestDay).toList();
      final materializedTraining = calendarWeeks.last.cells.length;

      if (materializedTraining < trainingSlots.length) {
        final lastCalWeek = calendarWeeks.last;
        final extraCells = [
          for (var i = materializedTraining; i < trainingSlots.length; i++)
            CalendarCell(
              workoutName: trainingSlots[i].name,
              orderIndex: trainingSlots[i].orderIndex,
            ),
        ];
        calendarWeeks[calendarWeeks.length - 1] = CalendarWeek(
          weekNumber: lastCalWeek.weekNumber,
          goal: lastCalWeek.goal,
          cells: [...lastCalWeek.cells, ...extraCells],
        );
      }
    }

    // ── Template-based future weeks ──────────────────────────────────────────
    final materializedCount = weeksList.length;
    if (materializedCount < meso.totalWeekCount) {
      final templateSlots = await (select(workoutTemplates).join([
        innerJoin(weekTemplates,
            weekTemplates.id.equalsExp(workoutTemplates.weekTemplateId)),
      ])
            ..where(weekTemplates.mesoTemplateId.equals(meso.mesoTemplateId) &
                workoutTemplates.isRestDay.equals(false))
            ..orderBy([OrderingTerm.asc(workoutTemplates.dayIndex)]))
          .map((row) => row.readTable(workoutTemplates))
          .get();

      for (var wn = materializedCount + 1;
          wn <= meso.totalWeekCount;
          wn++) {
        final goal =
            wn == meso.totalWeekCount ? WeekGoal.deload : WeekGoal.hard;
        final cells = [
          for (var i = 0; i < templateSlots.length; i++)
            CalendarCell(
              workoutName: templateSlots[i].name,
              orderIndex: i,
              workoutTemplateId: templateSlots[i].id,
            ),
        ];
        calendarWeeks.add(CalendarWeek(
          weekNumber: wn,
          goal: goal,
          cells: cells,
        ));
      }
    }

    return MesocycleCalendar(
      mesoName: meso.name,
      totalWeekCount: meso.totalWeekCount,
      weeks: calendarWeeks,
    );
  }

  /// Returns planned exercises for a workout that hasn't started yet.
  /// Returns an empty list if no plan has been generated.
  Future<List<PlannedExerciseEntry>> getPlannedExerciseList(
      int workoutId) async {
    final plannedWorkout = await (select(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(workoutId)))
        .getSingleOrNull();
    if (plannedWorkout == null) return [];

    final exercises = await (select(plannedExercises)
          ..where((pe) => pe.plannedWorkoutId.equals(plannedWorkout.id)))
        .get();

    final result = <PlannedExerciseEntry>[];
    for (final ex in exercises) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(ex.movementId)))
          .getSingle();
      final sets = await (select(plannedSets)
            ..where((ps) => ps.plannedExerciseId.equals(ex.id)))
          .get();
      result.add(PlannedExerciseEntry(
        movementName: movement.name,
        setCount: sets.length,
      ));
    }
    return result;
  }

  /// Returns movement names for a template workout (future non-materialized week).
  Future<List<String>> getTemplateExerciseNames(
      int workoutTemplateId) async {
    final exercises = await (select(exerciseTemplates)
          ..where((et) => et.workoutTemplateId.equals(workoutTemplateId))
          ..orderBy([(et) => OrderingTerm.asc(et.exerciseIndex)]))
        .get();

    final result = <String>[];
    for (final ex in exercises) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(ex.movementId)))
          .getSingle();
      result.add(movement.name);
    }
    return result;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<int> _createWeek(
      int mesocycleId, int weekNumber, WeekGoal goal) async {
    return into(weeks).insert(WeeksCompanion.insert(
      mesocycleId: mesocycleId,
      weekNumber: weekNumber,
      goal: goal,
      createdAt: DateTime.now(),
    ));
  }

  /// Materializes the first training day for a newly created week.
  ///
  /// For week 1: reads from the meso template.
  /// For week 2+: reads from [priorWeekId]'s workout rows.
  Future<Workout> _materializeFirstTrainingDay(
      int weekId, int mesocycleId, int? priorWeekId) async {
    final slots = priorWeekId == null
        ? await _templateSlotsForMeso(mesocycleId)
        : await _workoutSlotsFromWeek(priorWeekId);

    final first = slots.firstWhere((s) => !s.isRestDay);
    return _materializeTrainingDay(weekId, first.orderIndex, first.name);
  }

  Future<Workout> _materializeTrainingDay(
      int weekId, int orderIndex, String name) async {
    final id = await into(workouts).insert(WorkoutsCompanion.insert(
      weekId: weekId,
      name: name,
      orderIndex: orderIndex,
      isRestDay: false,
    ));
    return (select(workouts)..where((w) => w.id.equals(id))).getSingle();
  }

  /// Creates workout rows + completed_workout rows for rest day slots that fall
  /// before [upToOrderIndex] in the current week and haven't been created yet.
  Future<void> _advanceRestDaysBefore(
    int weekId,
    int upToOrderIndex,
    List<_WorkoutSlot> templateSlots,
    List<Workout> existingWorkouts,
    DateTime? lastCompletedDate,
  ) async {
    if (lastCompletedDate == null) return; // No prior date to squish from.

    final existingOrderIndexes = existingWorkouts.map((w) => w.orderIndex).toSet();
    final restSlots = templateSlots
        .where((s) =>
            s.isRestDay &&
            s.orderIndex < upToOrderIndex &&
            !existingOrderIndexes.contains(s.orderIndex))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (restSlots.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastCompletedDate.year,
      lastCompletedDate.month,
      lastCompletedDate.day,
    );

    var currentDay = lastDay;
    for (final slot in restSlots) {
      final candidate = currentDay.add(const Duration(days: 1));
      if (!candidate.isAfter(today)) currentDay = candidate;
      final timestamp =
          DateTime(currentDay.year, currentDay.month, currentDay.day, 12);

      final workoutId = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: slot.name,
        orderIndex: slot.orderIndex,
        isRestDay: true,
      ));
      await into(completedWorkouts).insert(CompletedWorkoutsCompanion.insert(
        workoutId: workoutId,
        startedAt: timestamp,
        completedAt: Value(timestamp),
        status: WorkoutStatus.completed,
      ));
    }
  }

  /// Returns the most recent completedAt date for any completed workout in this meso.
  Future<DateTime?> _lastCompletedDate(int mesocycleId) async {
    final row = await (select(completedWorkouts).join([
      innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
    ])
          ..where(weeks.mesocycleId.equals(mesocycleId) &
              completedWorkouts.completedAt.isNotNull())
          ..orderBy([OrderingTerm.desc(completedWorkouts.completedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.readTable(completedWorkouts).completedAt;
  }

  /// Returns ordered week slots derived from the meso template (for week 1).
  Future<List<_WorkoutSlot>> _templateSlotsForMeso(int mesocycleId) async {
    final meso = await (select(mesocycles)
          ..where((m) => m.id.equals(mesocycleId)))
        .getSingle();
    final wts = await (select(workoutTemplates).join([
      innerJoin(weekTemplates,
          weekTemplates.id.equalsExp(workoutTemplates.weekTemplateId)),
    ])
          ..where(weekTemplates.mesoTemplateId.equals(meso.mesoTemplateId))
          ..orderBy([OrderingTerm.asc(workoutTemplates.dayIndex)]))
        .map((row) => row.readTable(workoutTemplates))
        .get();
    return wts
        .map((wt) => _WorkoutSlot(
              orderIndex: wt.dayIndex,
              name: wt.name,
              isRestDay: wt.isRestDay,
            ))
        .toList();
  }

  /// Returns ordered week slots derived from a prior week's actual workout rows
  /// (for week 2+, preserving any schedule changes made in that week).
  Future<List<_WorkoutSlot>> _workoutSlotsFromWeek(int weekId) async {
    final ws = await (select(workouts)
          ..where((w) => w.weekId.equals(weekId))
          ..orderBy([(w) => OrderingTerm.asc(w.orderIndex)]))
        .get();
    return ws
        .map((w) => _WorkoutSlot(
              orderIndex: w.orderIndex,
              name: w.name,
              isRestDay: w.isRestDay,
            ))
        .toList();
  }

  /// Returns the ordered template slots for a given week, using the meso template
  /// for week 1 and the prior week's rows for week 2+.
  Future<List<_WorkoutSlot>> _getWeekTemplateSlots(
      Week currentWeek, List<Week> allWeeks) async {
    if (currentWeek.weekNumber == 1) {
      return _templateSlotsForMeso(currentWeek.mesocycleId);
    }
    final priorWeek =
        allWeeks.firstWhere((w) => w.weekNumber == currentWeek.weekNumber - 1);
    return _workoutSlotsFromWeek(priorWeek.id);
  }

  // ── Seed data ──────────────────────────────────────────────────────────────

  Future<void> _seedData() async {
    await transaction(() async {
      // ── Movements ──────────────────────────────────────────────────────────
      for (final s in kMovementSeeds) {
        await into(movements).insert(MovementsCompanion.insert(
          name: s.name,
          muscleGroup: s.muscleGroup,
          category: s.isRequiredDistance ? MovementCategory.cardio : MovementCategory.resistance,
          isRequiredReps: s.isRequiredReps,
          isRequiredWeight: s.isRequiredWeight,
          isRequiredTime: s.isRequiredTime,
          isRequiredDistance: Value(s.isRequiredDistance),
          minWeight: Value(s.minWeight),
          weightDelta: Value(s.weightDelta),
          bodyweightLoadFraction: Value(s.bodyweightLoadFraction),
        ));
      }

      // ── Meso templates ─────────────────────────────────────────────────────
      final allMovements = await select(movements).get();
      int idOf(String name, MuscleGroup mg) =>
          allMovements.firstWhere((m) => m.name == name && m.muscleGroup == mg).id;

      for (final tmpl in kMesoTemplateSeeds) {
        final mesoTemplateId = await into(mesoTemplates).insert(
          MesoTemplatesCompanion.insert(
            name: tmpl.name,
            createdAt: Value(DateTime.now()),
          ),
        );
        final weekTemplateId = await into(weekTemplates).insert(
          WeekTemplatesCompanion.insert(
            mesoTemplateId: mesoTemplateId,
            name: tmpl.weekName,
            workoutCount: tmpl.days.where((d) => !d.isRestDay).length,
          ),
        );
        for (var i = 0; i < tmpl.days.length; i++) {
          final day = tmpl.days[i];
          final wtId = await into(workoutTemplates).insert(
            WorkoutTemplatesCompanion.insert(
              weekTemplateId: weekTemplateId,
              name: day.name,
              isRestDay: day.isRestDay,
              dayIndex: i,
            ),
          );
          for (var j = 0; j < day.movements.length; j++) {
            final ref = day.movements[j];
            await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
              workoutTemplateId: wtId,
              movementId: idOf(ref.name, ref.muscleGroup),
              exerciseIndex: j,
            ));
          }
        }
      }

    });
  }
}

/// One exercise seeded with heuristic values inside the plan-generation
/// transaction, held for AI refinement after the transaction commits.
class _PlanSeed {
  const _PlanSeed({
    required this.plannedExerciseId,
    required this.movement,
    required this.priorSets,
    required this.targetCount,
  });

  final int plannedExerciseId;
  final Movement movement;
  final List<CompletedSet> priorSets;
  final int targetCount;
}

/// Cycle progress info for the start-workout screen — current position
/// plus gating flags for the add/remove-week affordances.
class MesoProgressInfo {
  const MesoProgressInfo({
    required this.weekNumber,
    required this.totalWeekCount,
    required this.trainingDayIndex,
    required this.totalTrainingDaysThisWeek,
    required this.isDeloadWeek,
    required this.canAddHardWeek,
    required this.canRemoveWeek,
  });

  final int weekNumber;
  final int totalWeekCount;
  final int trainingDayIndex;
  final int totalTrainingDaysThisWeek;
  final bool isDeloadWeek;
  final bool canAddHardWeek;
  final bool canRemoveWeek;
}

/// Lightweight slot descriptor used internally during lazy materialization.
class _WorkoutSlot {
  const _WorkoutSlot({
    required this.orderIndex,
    required this.name,
    required this.isRestDay,
  });

  final int orderIndex;
  final String name;
  final bool isRestDay;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'workout_of_record.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
