import 'package:drift/drift.dart';

import 'enums.dart';
import 'templates.dart';

class Mesocycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mesoTemplateId => integer().references(MesoTemplates, #id)();
  TextColumn get name => text()();
  IntColumn get totalWeekCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class Weeks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mesocycleId => integer().references(Mesocycles, #id)();
  IntColumn get weekNumber => integer()();
  TextColumn get goal => textEnum<WeekGoal>()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {mesocycleId, weekNumber},
      ];
}
