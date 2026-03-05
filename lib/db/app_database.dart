import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_state.dart';
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

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedData();
        },
      );

  Future<void> _seedData() async {
    await batch((b) {
      b.insertAll(movements, [
        MovementsCompanion.insert(
          name: 'Cable Fly',
          muscleGroup: MuscleGroup.chest,
          isRequiredReps: true,
          isRequiredWeight: true,
          isRequiredTime: false,
          minWeight: const Value(3.5),
          weightDelta: const Value(3.5),
        ),
        MovementsCompanion.insert(
          name: 'Dumbbell Press (Incline)',
          muscleGroup: MuscleGroup.chest,
          isRequiredReps: true,
          isRequiredWeight: true,
          isRequiredTime: false,
          minWeight: const Value(5.0),
          weightDelta: const Value(5.0),
        ),
        MovementsCompanion.insert(
          name: 'Barbell Bent Over Row',
          muscleGroup: MuscleGroup.back,
          isRequiredReps: true,
          isRequiredWeight: true,
          isRequiredTime: false,
          minWeight: const Value(45.0),
          weightDelta: const Value(5.0),
        ),
        MovementsCompanion.insert(
          name: 'Dumbbell Pullover',
          muscleGroup: MuscleGroup.back,
          isRequiredReps: true,
          isRequiredWeight: true,
          isRequiredTime: false,
          minWeight: const Value(5.0),
          weightDelta: const Value(5.0),
        ),
        MovementsCompanion.insert(
          name: 'Lying Dumbbell Curl',
          muscleGroup: MuscleGroup.biceps,
          isRequiredReps: true,
          isRequiredWeight: true,
          isRequiredTime: false,
          minWeight: const Value(5.0),
          weightDelta: const Value(5.0),
        ),
      ]);
    });

    await into(mesoTemplates).insert(
      MesoTemplatesCompanion.insert(name: 'Default Template'),
    );

    await into(appStates).insert(
      AppStatesCompanion(
        id: const Value(1),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
