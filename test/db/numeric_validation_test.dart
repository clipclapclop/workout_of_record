import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('completed sets reject unusable numbers before persistence', () async {
    await expectLater(
      database.saveCompletedSet(1, reps: 0),
      throwsArgumentError,
    );
    await expectLater(
      database.saveCompletedSet(1, weight: double.nan),
      throwsArgumentError,
    );
    await expectLater(
      database.saveCompletedSet(1, distance: double.infinity),
      throwsArgumentError,
    );
    await expectLater(
      database.saveCompletedSet(1, time: 0),
      throwsArgumentError,
    );

    await database.saveCompletedSet(1, reps: 1, weight: 0);
    await database.saveCompletedSet(1, reps: 1, weight: -50);
  });

  test('movement persistence validates planning numbers', () async {
    final movement = (await database.getMovements()).first;

    Future<void> update(MovementsCompanion values) =>
        database.updateMovement(values.copyWith(id: Value(movement.id)));

    expect(
      () => update(MovementsCompanion(minWeight: Value(double.nan))),
      throwsArgumentError,
    );
    expect(
      () => update(const MovementsCompanion(weightDelta: Value(0))),
      throwsArgumentError,
    );
    expect(
      () => update(
        MovementsCompanion(bodyweightLoadFraction: Value(double.infinity)),
      ),
      throwsArgumentError,
    );
    expect(
      () => update(const MovementsCompanion(restSeconds: Value(-1))),
      throwsArgumentError,
    );

    await update(const MovementsCompanion(minWeight: Value(-200)));
    await update(const MovementsCompanion(weightDelta: Value(2.5)));
    await update(const MovementsCompanion(bodyweightLoadFraction: Value(1)));
  });
}
