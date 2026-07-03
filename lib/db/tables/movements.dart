import 'package:drift/drift.dart';

import 'enums.dart';

class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name, muscleGroup},
      ];
  RealColumn get minWeight => real().nullable()();
  RealColumn get weightDelta => real().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get note1 => text().nullable()();
  TextColumn get note2 => text().nullable()();
  TextColumn get muscleGroup => textEnum<MuscleGroup>()();
  TextColumn get subMuscleGroup => text().nullable()();
  BoolColumn get isRequiredReps => boolean()();
  BoolColumn get isRequiredWeight => boolean()();
  BoolColumn get isRequiredTime => boolean()();
  BoolColumn get isRequiredDistance => boolean().withDefault(const Constant(false))();
  TextColumn get category => textEnum<MovementCategory>()();
  /// Portion of body weight included when calculating deload effective load.
  RealColumn get bodyweightLoadFraction =>
      real().withDefault(const Constant(0.0))();
  /// Null = use global default (60 s). 0 = timer disabled for this movement.
  IntColumn get restSeconds => integer().nullable()();
}
