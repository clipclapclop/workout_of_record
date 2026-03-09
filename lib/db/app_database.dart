import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_state.dart';
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
  AppStates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedData();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(appStates, appStates.currentCompletedWorkoutId);
          }
          if (from < 3) {
            await m.addColumn(mesoTemplates, mesoTemplates.createdAt);
          }
        },
      );

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<AppState> getAppState() =>
      (select(appStates)..where((s) => s.id.equals(1))).getSingle();

  /// Creates a new mesocycle from the given template and sets it as current.
  /// No weeks, workouts, or planned rows are created here — everything is lazy.
  Future<int> createMesocycle(
      int templateId, String name, int totalWeeks) async {
    return await transaction(() async {
      final mesocycleId = await into(mesocycles).insert(
        MesocyclesCompanion.insert(
          mesoTemplateId: templateId,
          name: name,
          totalWeekCount: totalWeeks,
          createdAt: DateTime.now(),
        ),
      );
      await (update(appStates)..where((s) => s.id.equals(1))).write(
        AppStatesCompanion(
          currentMesocycleId: Value(mesocycleId),
          currentCompletedWorkoutId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return mesocycleId;
    });
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
    await transaction(() async {
      // Idempotency check.
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
            plannedWorkoutId, workout.orderIndex, meso.mesoTemplateId);
      } else {
        await _generateFromPriorWeeks(plannedWorkoutId, workout, week);
      }
    });
  }

  /// Seeds the plan from the meso template (week 1 cold start).
  /// 2 null sets per exercise — user fills in values during the workout.
  Future<void> _generateFromTemplate(
      int plannedWorkoutId, int orderIndex, int mesoTemplateId) async {
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
      final peId = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: plannedWorkoutId,
          movementId: et.movementId,
        ),
      );
      await into(plannedSets)
          .insert(PlannedSetsCompanion.insert(plannedExerciseId: peId));
      await into(plannedSets)
          .insert(PlannedSetsCompanion.insert(plannedExerciseId: peId));
    }
  }

  /// Seeds the plan from the prior week's persistent completed exercises (week 2+).
  Future<void> _generateFromPriorWeeks(
      int plannedWorkoutId, Workout workout, Week week) async {
    final allWeeks = await (select(weeks)
          ..where((w) => w.mesocycleId.equals(week.mesocycleId))
          ..orderBy([(w) => OrderingTerm.asc(w.weekNumber)]))
        .get();

    // The prior week's completed_workout for this slot provides the exercise list.
    final priorWeek =
        allWeeks.firstWhere((w) => w.weekNumber == week.weekNumber - 1);
    final priorWorkout = await (select(workouts)
          ..where((w) =>
              w.weekId.equals(priorWeek.id) &
              w.orderIndex.equals(workout.orderIndex)))
        .getSingleOrNull();

    if (priorWorkout == null || priorWorkout.isRestDay) return;

    final priorCompleted = await (select(completedWorkouts)
          ..where((cw) => cw.workoutId.equals(priorWorkout.id)))
        .getSingleOrNull();

    if (priorCompleted == null) return; // Workout was skipped entirely.

    final priorExercises = await (select(completedExercises)
          ..where((ce) =>
              ce.completedWorkoutId.equals(priorCompleted.id) &
              ce.isPersistent.equals(true))
          ..orderBy([(ce) => OrderingTerm.asc(ce.orderIndex)]))
        .get();

    for (final priorEx in priorExercises) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(priorEx.movementId)))
          .getSingle();

      final peId = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: plannedWorkoutId,
          movementId: priorEx.movementId,
        ),
      );

      final plannedValues = await _resolvePlannedSets(
        priorEx.movementId,
        workout.orderIndex,
        week,
        allWeeks,
        movement,
      );

      for (final sv in plannedValues) {
        await into(plannedSets).insert(PlannedSetsCompanion(
          plannedExerciseId: Value(peId),
          reps: Value(sv.reps),
          weight: Value(sv.weight),
          time: Value(sv.time),
        ));
      }
    }
  }

  /// Walks backward through prior weeks to find the best completed set data
  /// for [movementId] at [workoutOrderIndex]. Skips weeks where the exercise
  /// was skipped. Falls back to cold start (2 null sets) if no history found.
  Future<List<PlannedSetValues>> _resolvePlannedSets(
    int movementId,
    int workoutOrderIndex,
    Week currentWeek,
    List<Week> allWeeks,
    Movement movement,
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
                ce.movementId.equals(movementId)))
          .getSingleOrNull();
      if (priorEx == null || priorEx.skipReason != null) continue;

      final allSets = await (select(completedSets)
            ..where((s) => s.completedExerciseId.equals(priorEx.id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      final nonSkipped = allSets.where((s) => s.skipReason == null).toList();

      return computeHeuristic(nonSkipped, currentWeek.goal, movement);
    }

    // No valid history found across any prior week — cold start.
    return [const PlannedSetValues(), const PlannedSetValues()];
  }

  Future<int> initializeWorkout(int workoutId) async {
    return await transaction(() async {
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

      await (update(appStates)..where((s) => s.id.equals(1))).write(
        AppStatesCompanion(
          currentCompletedWorkoutId: Value(completedWorkoutId),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return completedWorkoutId;
    });
  }

  Future<void> savePreWorkoutCheckin(
          PreWorkoutCheckinsCompanion checkin) =>
      into(preWorkoutCheckins).insert(checkin);

  Future<WorkoutData> getWorkoutData(int completedWorkoutId) async {
    final cw = await (select(completedWorkouts)
          ..where((w) => w.id.equals(completedWorkoutId)))
        .getSingle();
    final workout = await (select(workouts)
          ..where((w) => w.id.equals(cw.workoutId)))
        .getSingle();

    final plannedWorkout = await (select(plannedWorkouts)
          ..where((pw) => pw.workoutId.equals(cw.workoutId)))
        .getSingleOrNull();

    final completedExs = await (select(completedExercises)
          ..where((e) => e.completedWorkoutId.equals(completedWorkoutId))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();

    final exerciseDataList = <ExerciseData>[];
    for (final ce in completedExs) {
      final movement = await (select(movements)
            ..where((m) => m.id.equals(ce.movementId)))
          .getSingle();

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

      final postExCheckin = await (select(postExerciseCheckins)
            ..where((c) => c.completedExerciseId.equals(ce.id)))
          .getSingleOrNull();

      exerciseDataList.add(ExerciseData(
        completed: ce,
        movement: movement,
        sets: sets,
        postExerciseCheckin: postExCheckin,
      ));
    }

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
      double? time,
  }) =>
      (update(completedSets)..where((s) => s.id.equals(id))).write(
        CompletedSetsCompanion(
          reps: Value(reps),
          weight: Value(weight),
          time: Value(time),
        ),
      );

  Future<void> skipSet(int id, SkipReason reason) =>
      (update(completedSets)..where((s) => s.id.equals(id))).write(
        CompletedSetsCompanion(
          skipReason: Value(reason),
          reps: const Value(null),
          weight: const Value(null),
          time: const Value(null),
        ),
      );

  Future<void> clearCompletedSet(int id) =>
      (update(completedSets)..where((s) => s.id.equals(id))).write(
        const CompletedSetsCompanion(
          reps: Value(null),
          weight: Value(null),
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

      final movs = <Movement>[];
      for (final et in exTemplates) {
        final m = await (select(movements)..where((m) => m.id.equals(et.movementId))).getSingle();
        movs.add(m);
      }
      days.add(WorkoutDayData(template: wt, movements: movs));
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
  Future<void> deleteMesoTemplate(int id) async {
    final appState = await getAppState();
    if (appState.currentMesocycleId != null) {
      final meso = await (select(mesocycles)
            ..where((m) => m.id.equals(appState.currentMesocycleId!)))
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

      for (var j = 0; j < day.movementIds.length; j++) {
        await into(exerciseTemplates).insert(
          ExerciseTemplatesCompanion.insert(
            workoutTemplateId: workoutTemplateId,
            movementId: day.movementIds[j],
            exerciseIndex: j,
          ),
        );
      }
    }
  }

  Future<List<Movement>> getMovements() =>
      (select(movements)
        ..orderBy([
          (m) => OrderingTerm.asc(m.muscleGroup),
          (m) => OrderingTerm.asc(m.name),
        ]))
          .get();

  Future<void> updateMovement(MovementsCompanion companion) =>
      (update(movements)..where((m) => m.id.equals(companion.id.value)))
          .write(companion);

  /// Clears the current mesocycle so the app enters cold-boot / setup state.
  Future<void> clearCurrentMesocycle() =>
      (update(appStates)..where((s) => s.id.equals(1))).write(
        const AppStatesCompanion(
          currentMesocycleId: Value(null),
          currentCompletedWorkoutId: Value(null),
        ),
      );

  Future<void> finishWorkout(int completedWorkoutId) async {
    await transaction(() async {
      await (update(completedWorkouts)
            ..where((w) => w.id.equals(completedWorkoutId)))
          .write(CompletedWorkoutsCompanion(
        completedAt: Value(DateTime.now()),
        status: const Value(WorkoutStatus.completed),
      ));
      await (update(appStates)..where((s) => s.id.equals(1))).write(
        const AppStatesCompanion(
          currentCompletedWorkoutId: Value(null),
        ),
      );
    });
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
  }

  Future<void> setExercisePersistence(
          int completedExerciseId, bool isPersistent) =>
      (update(completedExercises)
            ..where((e) => e.id.equals(completedExerciseId)))
          .write(CompletedExercisesCompanion(isPersistent: Value(isPersistent)));

  /// Returns the expected date for the next workout: the day after the most
  /// recently completed workout in this mesocycle. Falls back to today.
  Future<DateTime> getExpectedWorkoutDate(int mesocycleId) async {
    final last = await _lastCompletedDate(mesocycleId);
    if (last == null) return DateTime.now();
    final lastDay = DateTime(last.year, last.month, last.day);
    return lastDay.add(const Duration(days: 1));
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
      await into(movements).insert(MovementsCompanion.insert(
        name: 'Cable Fly',
        muscleGroup: MuscleGroup.chest,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(3.5),
        weightDelta: const Value<double?>(3.5),
      ));
      final dumbbellPressId =
          await into(movements).insert(MovementsCompanion.insert(
        name: 'Dumbbell Press (Incline)',
        muscleGroup: MuscleGroup.chest,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(5.0),
        weightDelta: const Value<double?>(5.0),
      ));
      final barbellRowId =
          await into(movements).insert(MovementsCompanion.insert(
        name: 'Barbell Bent Over Row',
        muscleGroup: MuscleGroup.back,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(45.0),
        weightDelta: const Value<double?>(5.0),
      ));
      await into(movements).insert(MovementsCompanion.insert(
        name: 'Dumbbell Pullover',
        muscleGroup: MuscleGroup.back,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(5.0),
        weightDelta: const Value<double?>(5.0),
      ));
      await into(movements).insert(MovementsCompanion.insert(
        name: 'Lying Dumbbell Curl',
        muscleGroup: MuscleGroup.biceps,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(5.0),
        weightDelta: const Value<double?>(5.0),
      ));
      final cableTriId =
          await into(movements).insert(MovementsCompanion.insert(
        name: 'Cable Overhead Tricep Extension',
        muscleGroup: MuscleGroup.triceps,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(3.5),
        weightDelta: const Value<double?>(3.5),
      ));

      // ── Meso template ──────────────────────────────────────────────────────
      final mesoTemplateId = await into(mesoTemplates).insert(
        MesoTemplatesCompanion.insert(
          name: 'Default Template',
          createdAt: Value(DateTime.now()),
        ),
      );
      final weekTemplateId = await into(weekTemplates).insert(
        WeekTemplatesCompanion.insert(
          mesoTemplateId: mesoTemplateId,
          name: 'Standard Week',
          workoutCount: 2,
        ),
      );

      final wtDay1Id = await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          weekTemplateId: weekTemplateId,
          name: 'Day 1',
          isRestDay: false,
          dayIndex: 0,
        ),
      );
      await into(workoutTemplates).insert(WorkoutTemplatesCompanion.insert(
        weekTemplateId: weekTemplateId,
        name: 'Day 2',
        isRestDay: true,
        dayIndex: 1,
      ));
      final wtDay3Id = await into(workoutTemplates).insert(
        WorkoutTemplatesCompanion.insert(
          weekTemplateId: weekTemplateId,
          name: 'Day 3',
          isRestDay: false,
          dayIndex: 2,
        ),
      );
      await into(workoutTemplates).insert(WorkoutTemplatesCompanion.insert(
        weekTemplateId: weekTemplateId,
        name: 'Day 4',
        isRestDay: true,
        dayIndex: 3,
      ));
      await into(workoutTemplates).insert(WorkoutTemplatesCompanion.insert(
        weekTemplateId: weekTemplateId,
        name: 'Day 5',
        isRestDay: true,
        dayIndex: 4,
      ));

      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay1Id,
        movementId: dumbbellPressId,
        exerciseIndex: 0,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay1Id,
        movementId: cableTriId,
        exerciseIndex: 1,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay3Id,
        movementId: barbellRowId,
        exerciseIndex: 0,
      ));

      // ── App state (no active mesocycle — cold boot) ────────────────────────
      await into(appStates).insert(AppStatesCompanion(
        id: const Value(1),
        currentMesocycleId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }
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
