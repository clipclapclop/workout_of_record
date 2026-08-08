import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';

const _expectations = <int, _MigrationExpectation>{
  8: _MigrationExpectation(
    persistence: [0, 2, 0],
    completedAiPlanning: [1, 1, 1],
    plannedAiPlanning: [1, 1],
    templateAiPlanning: 1,
    customBodyweightLoad: 0.0,
    tibialis: null,
    pump: 'none',
  ),
  9: _MigrationExpectation(
    persistence: [0, 2, 0],
    completedAiPlanning: [1, 1, 1],
    plannedAiPlanning: [1, 1],
    templateAiPlanning: 1,
    customBodyweightLoad: 0.0,
    tibialis: null,
    pump: 'amazing',
  ),
  10: _MigrationExpectation(
    persistence: [0, 1, 2],
    completedAiPlanning: [1, 1, 1],
    plannedAiPlanning: [1, 1],
    templateAiPlanning: 1,
    customBodyweightLoad: 0.0,
    tibialis: null,
    pump: 'amazing',
  ),
  11: _MigrationExpectation(
    persistence: [0, 1, 2],
    completedAiPlanning: [1, 0, 1],
    plannedAiPlanning: [1, 0],
    templateAiPlanning: 0,
    customBodyweightLoad: 0.0,
    tibialis: null,
    pump: 'amazing',
  ),
  12: _MigrationExpectation(
    persistence: [0, 1, 2],
    completedAiPlanning: [1, 0, 1],
    plannedAiPlanning: [1, 0],
    templateAiPlanning: 0,
    customBodyweightLoad: 0.0,
    tibialis: 'lots',
    pump: 'amazing',
  ),
  13: _MigrationExpectation(
    persistence: [0, 1, 2],
    completedAiPlanning: [1, 0, 1],
    plannedAiPlanning: [1, 0],
    templateAiPlanning: 0,
    customBodyweightLoad: 0.35,
    tibialis: 'lots',
    pump: 'amazing',
  ),
};

void main() {
  final fixtureDirectory = Directory('test/fixtures/database');
  final fixtureName = RegExp(r'^schema_v(\d+)\.sqlite$');

  test('every supported source schema has a migration fixture', () {
    final fixtureVersions =
        fixtureDirectory
            .listSync()
            .whereType<File>()
            .map((file) => fixtureName.firstMatch(file.uri.pathSegments.last))
            .whereType<RegExpMatch>()
            .map((match) => int.parse(match.group(1)!))
            .toList()
          ..sort();

    final supportedVersions = [
      for (
        var version = minimumRestorableSchemaVersion;
        version <= currentDatabaseSchemaVersion;
        version++
      )
        version,
    ];
    expect(
      fixtureVersions,
      supportedVersions,
      reason: 'Add a fixture whenever the database schema changes.',
    );
    expect(
      _expectations.keys,
      supportedVersions,
      reason:
          'Add explicit semantic expectations whenever the database '
          'schema changes.',
    );
  });

  for (
    var sourceVersion = minimumRestorableSchemaVersion;
    sourceVersion <= currentDatabaseSchemaVersion;
    sourceVersion++
  ) {
    test('migrates schema $sourceVersion to the current schema', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'workout-of-record-migration-$sourceVersion-',
      );
      final migratedFile = File('${temporaryDirectory.path}/database.sqlite');
      final sourceFile = File(
        '${fixtureDirectory.path}/schema_v$sourceVersion.sqlite',
      );
      await sourceFile.copy(migratedFile.path);

      final database = AppDatabase.withExecutor(NativeDatabase(migratedFile));
      try {
        await database.customSelect('SELECT 1').get();

        expect(
          await _singleValue<int>(database, 'PRAGMA user_version'),
          currentDatabaseSchemaVersion,
        );
        expect(
          await _singleValue<String>(database, 'PRAGMA integrity_check'),
          'ok',
        );
        expect(
          await database.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );

        await _expectRepresentativeData(
          database,
          _expectations[sourceVersion]!,
        );
      } finally {
        await database.close();
        await temporaryDirectory.delete(recursive: true);
      }
    });
  }
}

Future<T> _singleValue<T>(AppDatabase database, String sql) async {
  final row = await database.customSelect(sql).getSingle();
  return row.data.values.single as T;
}

Future<void> _expectRepresentativeData(
  AppDatabase database,
  _MigrationExpectation migrationExpectation,
) async {
  final mesocycle = await database.customSelect('''
    SELECT m.name, m.total_week_count, w.week_number, w.goal
    FROM mesocycles m
    JOIN weeks w ON w.mesocycle_id = m.id
  ''').getSingle();
  expect(mesocycle.data, {
    'name': 'Fixture Mesocycle',
    'total_week_count': 4,
    'week_number': 2,
    'goal': 'hard',
  });

  final workouts = await database.customSelect('''
    SELECT w.name, cw.status, cw.skip_reason
    FROM workouts w
    JOIN completed_workouts cw ON cw.workout_id = w.id
    ORDER BY w.id
  ''').get();
  expect(workouts.map((row) => row.data).toList(), [
    {'name': 'Fixture Full Body', 'status': 'completed', 'skip_reason': null},
    {
      'name': 'Fixture Skipped Workout',
      'status': 'skipped',
      'skip_reason': 'illness',
    },
  ]);

  final template = await database.customSelect('''
    SELECT mt.name AS meso_name, wt.name AS workout_name,
           et.exercise_index, et.ai_planned
    FROM meso_templates mt
    JOIN week_templates week_t ON week_t.meso_template_id = mt.id
    JOIN workout_templates wt ON wt.week_template_id = week_t.id
    JOIN exercise_templates et ON et.workout_template_id = wt.id
  ''').getSingle();
  expect(template.data, {
    'meso_name': 'Fixture Strength Template',
    'workout_name': 'Fixture Full Body',
    'exercise_index': 0,
    'ai_planned': migrationExpectation.templateAiPlanning,
  });

  final movements = await database.customSelect('''
    SELECT name, muscle_group, note1, rest_seconds, bodyweight_load_fraction
    FROM movements
    ORDER BY id
  ''').get();
  expect(movements[0].data, {
    'name': 'Bodyweight Squat',
    'muscle_group': 'quads',
    'note1': 'Built-in fixture',
    'rest_seconds': 75,
    'bodyweight_load_fraction': 0.85,
  });
  expect(movements[1].data, {
    'name': 'Fixture Carry',
    'muscle_group': 'fullBody',
    'note1': 'Synthetic custom movement',
    'rest_seconds': 0,
    'bodyweight_load_fraction': migrationExpectation.customBodyweightLoad,
  });

  final plannedSets = await database.customSelect('''
    SELECT reps, weight, time, distance FROM planned_sets ORDER BY id
  ''').get();
  expect(plannedSets.map((row) => row.data).toList(), [
    {'reps': 8, 'weight': 135.5, 'time': null, 'distance': null},
    {'reps': null, 'weight': 52.5, 'time': 45.25, 'distance': 120.75},
  ]);

  final completedSets = await database.customSelect('''
    SELECT reps, weight, skip_reason FROM completed_sets ORDER BY id
  ''').get();
  expect(completedSets.map((row) => row.data).toList(), [
    {'reps': 8, 'weight': 135.5, 'skip_reason': null},
    {'reps': null, 'weight': null, 'skip_reason': 'muscleFatigue'},
    {'reps': null, 'weight': null, 'skip_reason': 'jointPain'},
    {'reps': null, 'weight': null, 'skip_reason': 'time'},
  ]);

  final completedExercises = await database.customSelect('''
    SELECT persistence, skip_reason, ai_planned
    FROM completed_exercises
    ORDER BY id
  ''').get();
  expect(completedExercises.map((row) => row.data).toList(), [
    {
      'persistence': migrationExpectation.persistence[0],
      'skip_reason': null,
      'ai_planned': migrationExpectation.completedAiPlanning[0],
    },
    {
      'persistence': migrationExpectation.persistence[1],
      'skip_reason': 'jointPain',
      'ai_planned': migrationExpectation.completedAiPlanning[1],
    },
    {
      'persistence': migrationExpectation.persistence[2],
      'skip_reason': 'time',
      'ai_planned': migrationExpectation.completedAiPlanning[2],
    },
  ]);

  // Schema 10 intentionally removed uniqueness from workout/order_index so
  // replaced exercises can retain their history at the same display position.
  await database.customStatement('''
    INSERT INTO completed_exercises
      (id, completed_workout_id, movement_id, order_index, persistence,
       skip_reason, ai_planned)
    VALUES (99, 1, 1, 0, 2, 'time', 0)
  ''');
  expect(
    await _singleValue<int>(database, '''
      SELECT COUNT(*) FROM completed_exercises
      WHERE completed_workout_id = 1 AND order_index = 0
    '''),
    2,
  );

  final plannedExercises = await database.customSelect('''
    SELECT ai_planned FROM planned_exercises ORDER BY id
  ''').get();
  expect(
    plannedExercises.map((row) => row.data['ai_planned']).toList(),
    migrationExpectation.plannedAiPlanning,
  );

  final checkins = await database.customSelect('''
    SELECT pre.quads, pre.sleep_quality, pre.mental_state, pre.tibialis,
           post.joint_pain, muscle.effort_level, muscle.volume_level,
           muscle.pump_level
    FROM pre_workout_checkins pre
    JOIN completed_workouts cw ON cw.workout_id = pre.workout_id
    JOIN completed_exercises ce ON ce.completed_workout_id = cw.id
    JOIN post_exercise_checkins post ON post.completed_exercise_id = ce.id
    JOIN post_muscle_group_checkins muscle
      ON muscle.completed_workout_id = cw.id
  ''').getSingle();
  expect(checkins.data, {
    'quads': 'some',
    'sleep_quality': 'great',
    'mental_state': 'notGood',
    'tibialis': migrationExpectation.tibialis,
    'joint_pain': 'aLittle',
    'effort_level': 'hard',
    'volume_level': 'aLot',
    'pump_level': migrationExpectation.pump,
  });
}

class _MigrationExpectation {
  const _MigrationExpectation({
    required this.persistence,
    required this.completedAiPlanning,
    required this.plannedAiPlanning,
    required this.templateAiPlanning,
    required this.customBodyweightLoad,
    required this.tibialis,
    required this.pump,
  });

  final List<int> persistence;
  final List<int> completedAiPlanning;
  final List<int> plannedAiPlanning;
  final int templateAiPlanning;
  final double customBodyweightLoad;
  final String? tibialis;
  final String pump;
}
