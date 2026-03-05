import 'package:drift/drift.dart';

import 'enums.dart';
import 'movements.dart';
import 'workouts.dart';

class PlannedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedWorkoutId =>
      integer().references(PlannedWorkouts, #id)();
  IntColumn get movementId => integer().references(Movements, #id)();
}

class CompletedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedWorkoutId =>
      integer().references(CompletedWorkouts, #id)();
  IntColumn get movementId => integer().references(Movements, #id)();
  IntColumn get orderIndex => integer()();
  BoolColumn get isPersistent =>
      boolean().withDefault(const Constant(true))();
  TextColumn get skipReason => textEnum<SkipReason>().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {completedWorkoutId, orderIndex},
      ];
}
