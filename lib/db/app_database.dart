import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_state.dart';
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
  int get schemaVersion => 2;

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
        },
      );

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<AppState> getAppState() =>
      (select(appStates)..where((s) => s.id.equals(1))).getSingle();

  Future<Workout?> getNextWorkout(int mesocycleId) {
    final query = select(workouts).join([
      innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
      leftOuterJoin(
          completedWorkouts, completedWorkouts.workoutId.equalsExp(workouts.id)),
    ])
      ..where(weeks.mesocycleId.equals(mesocycleId) &
          completedWorkouts.id.isNull() &
          workouts.isRestDay.equals(false))
      ..orderBy([
        OrderingTerm.asc(weeks.weekNumber),
        OrderingTerm.asc(workouts.orderIndex),
      ])
      ..limit(1);
    return query.map((row) => row.readTable(workouts)).getSingleOrNull();
  }

  Future<void> advanceRestDays(int mesocycleId, {DateTime? now}) async {
    await transaction(() async {
      // Find last completed workout for this mesocycle.
      final lastRow = await (select(completedWorkouts).join([
        innerJoin(workouts, workouts.id.equalsExp(completedWorkouts.workoutId)),
        innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
      ])
            ..where(weeks.mesocycleId.equals(mesocycleId))
            ..orderBy([
              OrderingTerm.desc(weeks.weekNumber),
              OrderingTerm.desc(workouts.orderIndex),
            ])
            ..limit(1))
          .getSingleOrNull();

      if (lastRow == null) return; // No completed workouts yet — first day is a training day.

      final lastCompleted = lastRow.readTable(completedWorkouts);
      final lastDate = lastCompleted.completedAt!;
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);

      // Find all pending (no completed_workout) items for this mesocycle in order.
      final pendingRows = await (select(workouts).join([
        innerJoin(weeks, weeks.id.equalsExp(workouts.weekId)),
        leftOuterJoin(completedWorkouts,
            completedWorkouts.workoutId.equalsExp(workouts.id)),
      ])
            ..where(weeks.mesocycleId.equals(mesocycleId) &
                completedWorkouts.id.isNull())
            ..orderBy([
              OrderingTerm.asc(weeks.weekNumber),
              OrderingTerm.asc(workouts.orderIndex),
            ]))
          .get();

      // Collect leading rest days only — stop at first training day.
      final restDays = <Workout>[];
      for (final row in pendingRows) {
        final w = row.readTable(workouts);
        if (!w.isRestDay) break;
        restDays.add(w);
      }

      if (restDays.isEmpty) return;

      final effectiveNow = now ?? DateTime.now();
      final today = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);

      // Squish algorithm: assign timestamps, clamping to yesterday at latest.
      var currentDay = lastDay;
      for (final restDay in restDays) {
        final candidate = currentDay.add(const Duration(days: 1));
        if (!candidate.isAfter(today)) {
          currentDay = candidate;
        }
        final timestamp =
            DateTime(currentDay.year, currentDay.month, currentDay.day, 12);
        await into(completedWorkouts).insert(CompletedWorkoutsCompanion.insert(
          workoutId: restDay.id,
          startedAt: timestamp,
          completedAt: Value(timestamp),
          status: WorkoutStatus.completed,
        ));
      }
    });
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

    // Find the planned workout so we can reach planned sets.
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

      // Find matching planned exercise (by movementId within this planned workout).
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

  // ── Seed data ──────────────────────────────────────────────────────────────

  Future<void> _seedData() async {
    await transaction(() async {
      // ── Movements ──────────────────────────────────────────────────────────
      final cableFlyId = await into(movements).insert(MovementsCompanion.insert(
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
      final dumbbellPulloverId =
          await into(movements).insert(MovementsCompanion.insert(
        name: 'Dumbbell Pullover',
        muscleGroup: MuscleGroup.back,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        minWeight: const Value<double?>(5.0),
        weightDelta: const Value<double?>(5.0),
      ));
      final lyingCurlId =
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
        MesoTemplatesCompanion.insert(name: 'Default Template'),
      );
      final weekTemplateId = await into(weekTemplates).insert(
        WeekTemplatesCompanion.insert(
          mesoTemplateId: mesoTemplateId,
          name: 'Standard Week',
          workoutCount: 5,
        ),
      );

      // Workout templates
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

      // Exercise templates — Day 1
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay1Id,
        movementId: cableFlyId,
        exerciseIndex: 0,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay1Id,
        movementId: dumbbellPressId,
        exerciseIndex: 1,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay1Id,
        movementId: cableTriId,
        exerciseIndex: 2,
      ));

      // Exercise templates — Day 3
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay3Id,
        movementId: barbellRowId,
        exerciseIndex: 0,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay3Id,
        movementId: dumbbellPulloverId,
        exerciseIndex: 1,
      ));
      await into(exerciseTemplates).insert(ExerciseTemplatesCompanion.insert(
        workoutTemplateId: wtDay3Id,
        movementId: lyingCurlId,
        exerciseIndex: 2,
      ));

      // ── Mesocycle ──────────────────────────────────────────────────────────
      final mesocycleId = await into(mesocycles).insert(
        MesocyclesCompanion.insert(
          mesoTemplateId: mesoTemplateId,
          name: 'Mesocycle 1',
          totalWeekCount: 2,
          createdAt: DateTime.now(),
        ),
      );
      final weekId = await into(weeks).insert(WeeksCompanion.insert(
        mesocycleId: mesocycleId,
        weekNumber: 1,
        goal: WeekGoal.hard,
        createdAt: DateTime.now(),
      ));

      // ── Workouts ───────────────────────────────────────────────────────────
      final w1Id = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: 'Day 1',
        orderIndex: 0,
        isRestDay: false,
      ));
      final w2Id = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: 'Day 2',
        orderIndex: 1,
        isRestDay: true,
      ));
      final w3Id = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: 'Day 3',
        orderIndex: 2,
        isRestDay: false,
      ));
      final w4Id = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: 'Day 4',
        orderIndex: 3,
        isRestDay: true,
      ));
      final w5Id = await into(workouts).insert(WorkoutsCompanion.insert(
        weekId: weekId,
        name: 'Day 5',
        orderIndex: 4,
        isRestDay: true,
      ));

      // ── Planned workouts ───────────────────────────────────────────────────
      final pw1Id = await into(plannedWorkouts).insert(
        PlannedWorkoutsCompanion.insert(workoutId: w1Id),
      );
      await into(plannedWorkouts)
          .insert(PlannedWorkoutsCompanion.insert(workoutId: w2Id));
      final pw3Id = await into(plannedWorkouts).insert(
        PlannedWorkoutsCompanion.insert(workoutId: w3Id),
      );
      await into(plannedWorkouts)
          .insert(PlannedWorkoutsCompanion.insert(workoutId: w4Id));
      await into(plannedWorkouts)
          .insert(PlannedWorkoutsCompanion.insert(workoutId: w5Id));

      // ── Planned exercises ──────────────────────────────────────────────────
      // Day 1
      final pe1Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw1Id,
          movementId: cableFlyId,
        ),
      );
      final pe2Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw1Id,
          movementId: dumbbellPressId,
        ),
      );
      final pe3Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw1Id,
          movementId: cableTriId,
        ),
      );

      // Day 3
      final pe4Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw3Id,
          movementId: barbellRowId,
        ),
      );
      final pe5Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw3Id,
          movementId: dumbbellPulloverId,
        ),
      );
      final pe6Id = await into(plannedExercises).insert(
        PlannedExercisesCompanion.insert(
          plannedWorkoutId: pw3Id,
          movementId: lyingCurlId,
        ),
      );

      // ── Planned sets ───────────────────────────────────────────────────────
      await batch((b) {
        b.insertAll(plannedSets, [
          // Day 1 — Cable Fly
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe1Id,
            reps: const Value<int?>(5),
            weight: const Value<double?>(7.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe1Id,
            reps: const Value<int?>(6),
            weight: const Value<double?>(10.5),
          ),
          // Day 1 — Dumbbell Press (Incline)
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe2Id,
            reps: const Value<int?>(7),
            weight: const Value<double?>(15.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe2Id,
            reps: const Value<int?>(8),
            weight: const Value<double?>(20.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe2Id,
            reps: const Value<int?>(9),
            weight: const Value<double?>(25.0),
          ),
          // Day 1 — Cable Overhead Tricep Extension
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe3Id,
            reps: const Value<int?>(3),
            weight: const Value<double?>(10.0),
          ),
          // Day 3 — Barbell Bent Over Row
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe4Id,
            reps: const Value<int?>(8),
            weight: const Value<double?>(50.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe4Id,
            reps: const Value<int?>(9),
            weight: const Value<double?>(55.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe4Id,
            reps: const Value<int?>(10),
            weight: const Value<double?>(55.0),
          ),
          // Day 3 — Dumbbell Pullover
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe5Id,
            reps: const Value<int?>(6),
            weight: const Value<double?>(35.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe5Id,
            reps: const Value<int?>(7),
            weight: const Value<double?>(45.0),
          ),
          // Day 3 — Lying Dumbbell Curl
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe6Id,
            reps: const Value<int?>(3),
            weight: const Value<double?>(10.0),
          ),
          PlannedSetsCompanion.insert(
            plannedExerciseId: pe6Id,
            reps: const Value<int?>(4),
            weight: const Value<double?>(15.0),
          ),
        ]);
      });

      // ── App state ──────────────────────────────────────────────────────────
      await into(appStates).insert(AppStatesCompanion(
        id: const Value(1),
        currentMesocycleId: Value(mesocycleId),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }
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
