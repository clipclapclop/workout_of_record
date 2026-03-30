import 'package:drift/drift.dart';

import 'enums.dart';
import 'movements.dart';
import 'workouts.dart';

class PlannedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedWorkoutId =>
      integer().references(PlannedWorkouts, #id)();
  IntColumn get movementId => integer().references(Movements, #id)();
  BoolColumn get autoProgress =>
      boolean().named('ai_planned').withDefault(const Constant(true))();
}

class CompletedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedWorkoutId =>
      integer().references(CompletedWorkouts, #id)();
  IntColumn get movementId => integer().references(Movements, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get persistence =>
      intEnum<Persistence>().withDefault(const Constant(0))();
  TextColumn get skipReason => textEnum<SkipReason>().nullable()();
  BoolColumn get autoProgress =>
      boolean().named('ai_planned').withDefault(const Constant(true))();
}
