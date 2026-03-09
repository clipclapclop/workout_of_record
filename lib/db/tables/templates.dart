import 'package:drift/drift.dart';

import 'movements.dart';

class MesoTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WeekTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mesoTemplateId => integer().references(MesoTemplates, #id)();
  TextColumn get name => text()();
  IntColumn get workoutCount => integer()();
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekTemplateId => integer().references(WeekTemplates, #id)();
  TextColumn get name => text()();
  BoolColumn get isRestDay => boolean()();
  IntColumn get dayIndex => integer()();
}

class ExerciseTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutTemplateId =>
      integer().references(WorkoutTemplates, #id)();
  IntColumn get movementId => integer().references(Movements, #id)();
  IntColumn get exerciseIndex => integer()();
}
