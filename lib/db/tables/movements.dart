import 'package:drift/drift.dart';

import 'enums.dart';

class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
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
  TextColumn get category => textEnum<MovementCategory>()();
}
