import 'package:drift/drift.dart';

import 'enums.dart';
import 'mesocycles.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekId => integer().references(Weeks, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();
  BoolColumn get isRestDay => boolean()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {weekId, orderIndex},
      ];
}

class PlannedWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id).unique()();
}

class CompletedWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id).unique()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => textEnum<WorkoutStatus>()();
  TextColumn get skipReason => textEnum<WorkoutSkipReason>().nullable()();
}
