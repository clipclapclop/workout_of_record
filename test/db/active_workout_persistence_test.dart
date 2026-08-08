import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/workout_recovery_service.dart';

AppDatabase _openMemoryDatabase() =>
    AppDatabase.withExecutor(NativeDatabase.memory());

class _WorkoutFixture {
  const _WorkoutFixture({
    required this.mesocycleId,
    required this.workoutId,
    required this.completedWorkoutId,
  });

  final int mesocycleId;
  final int workoutId;
  final int completedWorkoutId;
}

Future<_WorkoutFixture> _startWorkout(
  AppDatabase database, {
  int totalWeeks = 2,
}) async {
  final template = (await database.getMesoTemplates()).first;
  final mesocycleId = await database.createMesocycle(
    template.id,
    'Regression Cycle',
    totalWeeks,
  );
  final workout = await database.getOrCreateNextWorkout(mesocycleId);
  await database.generatePlannedWorkout(workout!.id);
  final completedWorkoutId = await database.initializeWorkout(workout.id);
  return _WorkoutFixture(
    mesocycleId: mesocycleId,
    workoutId: workout.id,
    completedWorkoutId: completedWorkoutId,
  );
}

Future<int> _completeWorkout(AppDatabase database, int workoutId) async {
  await database.generatePlannedWorkout(workoutId);
  final completedWorkoutId = await database.initializeWorkout(workoutId);
  await database.finishWorkout(completedWorkoutId);
  return completedWorkoutId;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await AppPreferences.setAiEnabled(false);
  });

  test(
    'skipSet and clearCompletedSet persist the complete state transition',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database);
      final before = await database.getWorkoutData(fixture.completedWorkoutId);
      final setId = before.exercises.first.sets.first.completed.id;

      await database.saveCompletedSet(setId, reps: 9, weight: 42.5);
      await database.skipSet(setId, SkipReason.jointPain);

      var stored = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first.sets.first.completed;
      expect(stored.skipReason, SkipReason.jointPain);
      expect(stored.reps, isNull);
      expect(stored.weight, isNull);
      expect(stored.distance, isNull);
      expect(stored.time, isNull);

      await database.clearCompletedSet(setId);

      stored = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first.sets.first.completed;
      expect(stored.skipReason, isNull);
      expect(stored.reps, isNull);
      expect(stored.weight, isNull);
    },
  );

  test(
    'skipping and unskipping an exercise preserves its set identity and order',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database);
      final exercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      final originalSetIds = [
        for (final set in exercise.sets) set.completed.id,
      ];
      await database.saveCompletedSet(
        originalSetIds.first,
        reps: 8,
        weight: 50,
      );

      await database.skipExercise(
        exercise.completed.id,
        SkipReason.systemicFatigue,
      );

      var storedExercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      expect(storedExercise.completed.skipReason, SkipReason.systemicFatigue);
      expect([
        for (final set in storedExercise.sets) set.completed.id,
      ], originalSetIds);
      for (final set in storedExercise.sets) {
        expect(set.completed.skipReason, SkipReason.systemicFatigue);
        expect(set.completed.reps, isNull);
        expect(set.completed.weight, isNull);
      }

      await database.unskipExercise(exercise.completed.id);

      storedExercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      expect(storedExercise.completed.skipReason, isNull);
      expect([
        for (final set in storedExercise.sets) set.completed.id,
      ], originalSetIds);
      expect(
        storedExercise.sets.every((set) => set.completed.skipReason == null),
        isTrue,
      );
      expect(
        storedExercise.sets.every((set) => set.completed.reps == null),
        isTrue,
      );
    },
  );

  test(
    'a skipped exercise remains history and does not cold-start later plans',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database, totalWeeks: 3);
      final week1Exercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      for (final set in week1Exercise.sets) {
        await database.saveCompletedSet(set.completed.id, reps: 8, weight: 60);
      }
      await database.finishWorkout(fixture.completedWorkoutId);

      for (var day = 0; day < 4; day++) {
        final workout = await database.getOrCreateNextWorkout(
          fixture.mesocycleId,
        );
        await _completeWorkout(database, workout!.id);
      }

      final week2Workout = await database.getOrCreateNextWorkout(
        fixture.mesocycleId,
      );
      await database.generatePlannedWorkout(week2Workout!.id);
      final week2CompletedId = await database.initializeWorkout(
        week2Workout.id,
      );
      final week2Exercise = (await database.getWorkoutData(week2CompletedId))
          .exercises
          .firstWhere(
            (exercise) => exercise.movement.id == week1Exercise.movement.id,
          );
      await database.skipExercise(
        week2Exercise.completed.id,
        SkipReason.muscleFatigue,
      );
      await database.finishWorkout(week2CompletedId);

      final history = await database.getMovementHistory(
        week1Exercise.movement.id,
      );
      expect(history, hasLength(2));
      final skippedHistory = history.singleWhere(
        (entry) => entry.exercise.id == week2Exercise.completed.id,
      );
      expect(skippedHistory.exercise.skipReason, SkipReason.muscleFatigue);
      expect(
        skippedHistory.sets.every(
          (set) => set.skipReason == SkipReason.muscleFatigue,
        ),
        isTrue,
      );

      for (var day = 0; day < 4; day++) {
        final workout = await database.getOrCreateNextWorkout(
          fixture.mesocycleId,
        );
        await _completeWorkout(database, workout!.id);
      }

      final week3Workout = await database.getOrCreateNextWorkout(
        fixture.mesocycleId,
      );
      await database.generatePlannedWorkout(week3Workout!.id);
      final plannedWorkout = await (database.select(
        database.plannedWorkouts,
      )..where((row) => row.workoutId.equals(week3Workout.id))).getSingle();
      final plannedExercise =
          await (database.select(database.plannedExercises)..where(
                (row) =>
                    row.plannedWorkoutId.equals(plannedWorkout.id) &
                    row.movementId.equals(week1Exercise.movement.id),
              ))
              .getSingle();
      final plannedSets =
          await (database.select(database.plannedSets)
                ..where(
                  (row) => row.plannedExerciseId.equals(plannedExercise.id),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.id)]))
              .get();

      expect(plannedSets, isNotEmpty);
      expect(plannedSets.every((set) => set.reps != null), isTrue);
      expect(plannedSets.every((set) => set.weight != null), isTrue);
    },
  );

  test(
    'adding and deleting sets preserves the remaining order and count',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database);
      final exercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      final originalIds = [for (final set in exercise.sets) set.completed.id];

      final addedId = await database.addSet(exercise.completed.id);
      var stored = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      expect(
        [for (final set in stored.sets) set.completed.id],
        [...originalIds, addedId],
      );

      await database.deleteSet(originalIds.last);
      stored = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      expect(stored.sets, hasLength(originalIds.length));
      expect(
        [for (final set in stored.sets) set.completed.id],
        [originalIds.first, addedId],
      );
    },
  );

  test(
    'skipping a workout records its reason and selects the next workout',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final template = (await database.getMesoTemplates()).first;
      final mesocycleId = await database.createMesocycle(
        template.id,
        'Skipped Workout Cycle',
        2,
      );
      final monday = await database.getOrCreateNextWorkout(mesocycleId);

      await database.skipWorkout(monday!.id, WorkoutSkipReason.illness);

      final skipped = await (database.select(
        database.completedWorkouts,
      )..where((row) => row.workoutId.equals(monday.id))).getSingle();
      expect(skipped.status, WorkoutStatus.skipped);
      expect(skipped.skipReason, WorkoutSkipReason.illness);
      expect(skipped.completedAt, isNotNull);
      final next = await database.getOrCreateNextWorkout(mesocycleId);
      expect(next!.name, 'Tuesday');
    },
  );

  test(
    'finishing advances the cycle and reconciliation clears stale pointers',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database, totalWeeks: 2);
      await AppPreferences.setCurrentMesocycleId(fixture.mesocycleId);
      await AppPreferences.setCurrentCompletedWorkoutId(
        fixture.completedWorkoutId,
      );

      await database.finishWorkout(fixture.completedWorkoutId);
      await WorkoutRecoveryService.reconcileNavigationPointers(database);

      expect(AppPreferences.getCurrentCompletedWorkoutId(), isNull);
      expect(AppPreferences.getCurrentMesocycleId(), fixture.mesocycleId);
      var next = await database.getOrCreateNextWorkout(fixture.mesocycleId);
      expect(next!.name, 'Tuesday');

      for (var day = 0; day < 4; day++) {
        await _completeWorkout(database, next!.id);
        next = await database.getOrCreateNextWorkout(fixture.mesocycleId);
      }
      final week2 = await (database.select(
        database.weeks,
      )..where((row) => row.id.equals(next!.weekId))).getSingle();
      expect(week2.weekNumber, 2);
      expect(next!.name, 'Monday');

      int? lastCompletedId;
      for (var day = 0; day < 5; day++) {
        lastCompletedId = await _completeWorkout(database, next!.id);
        next = await database.getOrCreateNextWorkout(fixture.mesocycleId);
      }
      expect(next, isNull);
      await AppPreferences.setCurrentCompletedWorkoutId(lastCompletedId);
      await WorkoutRecoveryService.reconcileNavigationPointers(database);
      expect(AppPreferences.getCurrentCompletedWorkoutId(), isNull);
      expect(AppPreferences.getCurrentMesocycleId(), isNull);
    },
  );

  test(
    'reopening the database reconstructs the persisted active workout',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'active_workout_recovery_',
      );
      final path = '${directory.path}/workouts.sqlite';
      AppDatabase? database = AppDatabase.withExecutor(
        NativeDatabase(File(path)),
      );
      AppDatabase? reopened;
      try {
        final fixture = await _startWorkout(database);
        final exercise = (await database.getWorkoutData(
          fixture.completedWorkoutId,
        )).exercises.first;
        await database.saveCompletedSet(
          exercise.sets.first.completed.id,
          reps: 11,
          weight: 47.5,
        );
        await database.skipSet(
          exercise.sets.last.completed.id,
          SkipReason.time,
        );
        final addedId = await database.addSet(exercise.completed.id);
        await database.saveCompletedSet(addedId, reps: 7, weight: 47.5);
        await database.close();
        database = null;

        reopened = AppDatabase.withExecutor(NativeDatabase(File(path)));
        await AppPreferences.setCurrentMesocycleId(null);
        await AppPreferences.setCurrentCompletedWorkoutId(null);
        await WorkoutRecoveryService.reconcileNavigationPointers(reopened);

        expect(
          AppPreferences.getCurrentCompletedWorkoutId(),
          fixture.completedWorkoutId,
        );
        expect(AppPreferences.getCurrentMesocycleId(), fixture.mesocycleId);
        final recovered = await reopened.getWorkoutData(
          fixture.completedWorkoutId,
        );
        expect(recovered.completedWorkout.status, WorkoutStatus.active);
        expect(recovered.completedWorkout.completedAt, isNull);
        final recoveredSets = recovered.exercises.first.sets;
        expect(recoveredSets, hasLength(3));
        expect(recoveredSets[0].completed.reps, 11);
        expect(recoveredSets[0].completed.weight, 47.5);
        expect(recoveredSets[1].completed.skipReason, SkipReason.time);
        expect(recoveredSets[2].completed.id, addedId);
        expect(recoveredSets[2].completed.reps, 7);
      } finally {
        await database?.close();
        await reopened?.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'completed history values ignore later planning and preference changes',
    () async {
      final database = _openMemoryDatabase();
      addTearDown(database.close);
      final fixture = await _startWorkout(database);
      final exercise = (await database.getWorkoutData(
        fixture.completedWorkoutId,
      )).exercises.first;
      await database.saveCompletedSet(
        exercise.sets.first.completed.id,
        reps: 10,
        weight: 52.5,
      );
      await database.skipSet(exercise.sets.last.completed.id, SkipReason.time);
      await database.finishWorkout(fixture.completedWorkoutId);

      final before = (await database.getMovementHistory(
        exercise.movement.id,
      )).single;
      final template = (await database.getMesoTemplates()).first;
      await (database.update(database.mesoTemplates)
            ..where((row) => row.id.equals(template.id)))
          .write(const MesoTemplatesCompanion(name: Value('Revised Template')));
      await (database.update(database.movements)
            ..where((row) => row.id.equals(exercise.movement.id)))
          .write(const MovementsCompanion(weightDelta: Value(7.5)));
      await AppPreferences.setUnitsMetric(true);
      await AppPreferences.setWeight(82);

      final after = (await database.getMovementHistory(
        exercise.movement.id,
      )).single;
      expect(after.mesoId, before.mesoId);
      expect(after.mesoName, before.mesoName);
      expect(after.weekNumber, before.weekNumber);
      expect(after.workoutName, before.workoutName);
      expect(after.exercise.id, before.exercise.id);
      expect(after.exercise.movementId, before.exercise.movementId);
      expect(
        [for (final set in after.sets) set.id],
        [for (final set in before.sets) set.id],
      );
      expect(after.sets.first.reps, 10);
      expect(after.sets.first.weight, 52.5);
      expect(after.sets.last.skipReason, SkipReason.time);
    },
  );
}
