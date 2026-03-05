import 'package:drift/drift.dart';

import 'enums.dart';
import 'exercises.dart';
import 'workouts.dart';

class PreWorkoutCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id).unique()();
  TextColumn get quads => textEnum<Soreness>().nullable()();
  TextColumn get hamstrings => textEnum<Soreness>().nullable()();
  TextColumn get abs => textEnum<Soreness>().nullable()();
  TextColumn get chest => textEnum<Soreness>().nullable()();
  TextColumn get back => textEnum<Soreness>().nullable()();
  TextColumn get biceps => textEnum<Soreness>().nullable()();
  TextColumn get triceps => textEnum<Soreness>().nullable()();
  TextColumn get traps => textEnum<Soreness>().nullable()();
  TextColumn get forearms => textEnum<Soreness>().nullable()();
  TextColumn get glutes => textEnum<Soreness>().nullable()();
  TextColumn get calves => textEnum<Soreness>().nullable()();
  TextColumn get shoulders => textEnum<Soreness>().nullable()();
  TextColumn get sleepQuality => textEnum<CurrentState>().nullable()();
  TextColumn get vimVigor => textEnum<CurrentState>().nullable()();
  TextColumn get mentalState => textEnum<CurrentState>().nullable()();
}

class PostExerciseCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedExerciseId =>
      integer().references(CompletedExercises, #id).unique()();
  TextColumn get jointPain => textEnum<Soreness>()();
}

class PostMuscleGroupCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedWorkoutId =>
      integer().references(CompletedWorkouts, #id)();
  TextColumn get muscleGroup => textEnum<MuscleGroup>()();
  TextColumn get effortLevel => textEnum<Effort>()();
  TextColumn get volumeLevel => textEnum<Volume>()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {completedWorkoutId, muscleGroup},
      ];
}
