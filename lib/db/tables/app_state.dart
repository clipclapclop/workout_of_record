import 'package:drift/drift.dart';

import 'mesocycles.dart';

// Singleton table — always has exactly one row with id = 1.
class AppStates extends Table {
  @override
  String get tableName => 'app_state';

  IntColumn get id => integer()();
  IntColumn get currentMesocycleId =>
      integer().nullable().references(Mesocycles, #id)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
