import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/template_data.dart';

AppDatabase _openDatabase() =>
    AppDatabase.withExecutor(NativeDatabase.memory());

Future<({int mesocycleId, int workoutId})> _createFinalWorkout(
  AppDatabase database,
) async {
  final templateId = await database.createMesoTemplate('One workout', const [
    WorkoutDaySpec(name: 'Only workout', isRestDay: false, exercises: []),
  ]);
  final mesocycleId = await database.createMesocycle(
    templateId,
    'One workout cycle',
    1,
  );
  final workout = await database.getOrCreateNextWorkout(mesocycleId);
  return (mesocycleId: mesocycleId, workoutId: workout!.id);
}

Future<void> _blockMesocycleCompletion(AppDatabase database) =>
    database.customStatement('''
      CREATE TRIGGER block_mesocycle_completion
      BEFORE UPDATE OF completed_at ON mesocycles
      BEGIN
        SELECT RAISE(ABORT, 'blocked for test');
      END;
    ''');

void main() {
  test('an unused template can be deleted', () async {
    final database = _openDatabase();
    addTearDown(database.close);
    final templateId = await database.createMesoTemplate('Disposable', const [
      WorkoutDaySpec(name: 'Day', isRestDay: false, exercises: []),
    ]);

    await database.deleteMesoTemplate(templateId);

    expect(
      await (database.select(
        database.mesoTemplates,
      )..where((row) => row.id.equals(templateId))).getSingleOrNull(),
      isNull,
    );
    expect(
      await (database.select(
        database.weekTemplates,
      )..where((row) => row.mesoTemplateId.equals(templateId))).get(),
      isEmpty,
    );
  });

  test('a template used by an active mesocycle cannot be deleted', () async {
    final database = _openDatabase();
    addTearDown(database.close);
    final template = (await database.getMesoTemplates()).first;
    await database.createMesocycle(template.id, 'Active cycle', 2);

    await expectLater(
      database.deleteMesoTemplate(template.id),
      throwsA(isA<TemplateInUseException>()),
    );

    expect(
      await (database.select(
        database.mesoTemplates,
      )..where((row) => row.id.equals(template.id))).getSingleOrNull(),
      isNotNull,
    );
  });

  test('a template used by a completed mesocycle cannot be deleted', () async {
    final database = _openDatabase();
    addTearDown(database.close);
    final template = (await database.getMesoTemplates()).first;
    final mesocycleId = await database.createMesocycle(
      template.id,
      'Completed cycle',
      1,
    );
    await (database.update(database.mesocycles)
          ..where((row) => row.id.equals(mesocycleId)))
        .write(MesocyclesCompanion(completedAt: Value(DateTime.now())));

    await expectLater(
      database.deleteMesoTemplate(template.id),
      throwsA(isA<TemplateInUseException>()),
    );

    expect(
      await (database.select(
        database.mesoTemplates,
      )..where((row) => row.id.equals(template.id))).getSingleOrNull(),
      isNotNull,
    );
  });

  test(
    'failed workout finish rolls back workout and mesocycle state',
    () async {
      final database = _openDatabase();
      addTearDown(database.close);
      final fixture = await _createFinalWorkout(database);
      await database.generatePlannedWorkout(fixture.workoutId);
      final completedWorkoutId = await database.initializeWorkout(
        fixture.workoutId,
      );
      await _blockMesocycleCompletion(database);

      await expectLater(
        database.finishWorkout(completedWorkoutId),
        throwsA(anything),
      );

      final workout = await (database.select(
        database.completedWorkouts,
      )..where((row) => row.id.equals(completedWorkoutId))).getSingle();
      final mesocycle = await (database.select(
        database.mesocycles,
      )..where((row) => row.id.equals(fixture.mesocycleId))).getSingle();
      expect(workout.status, WorkoutStatus.active);
      expect(workout.completedAt, isNull);
      expect(mesocycle.completedAt, isNull);
    },
  );

  test('failed workout skip rolls back workout and mesocycle state', () async {
    final database = _openDatabase();
    addTearDown(database.close);
    final fixture = await _createFinalWorkout(database);
    await _blockMesocycleCompletion(database);

    await expectLater(
      database.skipWorkout(fixture.workoutId, WorkoutSkipReason.illness),
      throwsA(anything),
    );

    expect(
      await (database.select(database.completedWorkouts)
            ..where((row) => row.workoutId.equals(fixture.workoutId)))
          .getSingleOrNull(),
      isNull,
    );
    final mesocycle = await (database.select(
      database.mesocycles,
    )..where((row) => row.id.equals(fixture.mesocycleId))).getSingle();
    expect(mesocycle.completedAt, isNull);
  });
}
