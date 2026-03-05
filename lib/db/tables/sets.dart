import 'package:drift/drift.dart';

import 'enums.dart';
import 'exercises.dart';

class PlannedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedExerciseId =>
      integer().references(PlannedExercises, #id)();
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get time => real().nullable()();
}

class CompletedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedExerciseId =>
      integer().references(CompletedExercises, #id)();
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get time => real().nullable()();
  TextColumn get skipReason => textEnum<SkipReason>().nullable()();
}
