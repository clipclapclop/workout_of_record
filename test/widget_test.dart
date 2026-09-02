import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/workout_data.dart';
import 'package:workout_of_record/widgets/set_ui_state.dart';
import 'package:workout_of_record/widgets/set_widget.dart';

void main() {
  testWidgets('set fields use pounds and miles', (tester) async {
    final movement = Movement(
      id: 1,
      name: 'Loaded carry',
      muscleGroup: MuscleGroup.other,
      isRequiredReps: false,
      isRequiredWeight: true,
      isRequiredTime: false,
      isRequiredDistance: true,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    final state = SetUiState(
      weight: '100',
      distance: '1',
      isChecked: false,
      isSkipped: false,
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SetWidget(
          setData: SetData(
            completed: CompletedSet(id: 1, completedExerciseId: 1),
          ),
          movement: movement,
          setNum: 1,
          isLastSet: true,
          isExSkipped: false,
          isLocked: false,
          isChecked: false,
          isSkipped: false,
          state: state,
          onTimerReset: () {},
          onToggle: (_) async {},
          onSkip: () async {},
          onDelete: () async {},
        ),
      ),
    ));

    expect(find.text('lbs'), findsOneWidget);
    expect(find.text('mi'), findsOneWidget);
    expect(find.text('kg'), findsNothing);
    expect(find.text('km'), findsNothing);
  });

  test('set validation rejects non-finite values and permits assistance', () {
    const movement = Movement(
      id: 1,
      name: 'Timed loaded carry',
      muscleGroup: MuscleGroup.other,
      isRequiredReps: true,
      isRequiredWeight: true,
      isRequiredTime: true,
      isRequiredDistance: true,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    final state = SetUiState(
      reps: '8',
      weight: '-40',
      distance: '1',
      time: '60',
      isChecked: false,
      isSkipped: false,
    );
    addTearDown(state.dispose);

    expect(state.canCheck(movement), isTrue);

    state.weightCtrl.text = 'NaN';
    expect(state.canCheck(movement), isFalse);
    state.weightCtrl.text = '-40';

    state.distanceCtrl.text = 'Infinity';
    expect(state.canCheck(movement), isFalse);
    state.distanceCtrl.text = '1';

    state.timeCtrl.text = 'NaN';
    expect(state.canCheck(movement), isFalse);
    state.timeCtrl.text = '60';

    state.repsCtrl.text = '0';
    expect(state.canCheck(movement), isFalse);
  });

  testWidgets('only the first interaction with a set resets the timer',
      (tester) async {
    const movement = Movement(
      id: 1,
      name: 'Curl',
      muscleGroup: MuscleGroup.biceps,
      isRequiredReps: true,
      isRequiredWeight: false,
      isRequiredTime: false,
      isRequiredDistance: false,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    var resets = 0;

    Future<void> pumpSet(SetUiState state, Key key) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SetWidget(
                key: key,
                setData: SetData(
                  completed: const CompletedSet(
                    id: 1,
                    completedExerciseId: 1,
                  ),
                ),
                movement: movement,
                setNum: 1,
                isLastSet: true,
                isExSkipped: false,
                isLocked: false,
                isChecked: false,
                isSkipped: false,
                state: state,
                onTimerReset: () => resets++,
                onToggle: (_) async {},
                onSkip: () async {},
                onDelete: () async {},
              ),
            ),
          ),
        );

    final fieldFirstState = SetUiState(
      reps: '10',
      isChecked: false,
      isSkipped: false,
    );
    addTearDown(fieldFirstState.dispose);
    await pumpSet(fieldFirstState, const ValueKey('field-first'));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '8');
    await tester.tap(find.byType(Checkbox));
    expect(resets, 1);

    final checkboxFirstState = SetUiState(
      reps: '10',
      isChecked: false,
      isSkipped: false,
    );
    addTearDown(checkboxFirstState.dispose);
    resets = 0;
    await pumpSet(checkboxFirstState, const ValueKey('checkbox-first'));

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    expect(resets, 1);
  });

  testWidgets('editing reps does not change following sets', (tester) async {
    final movement = Movement(
      id: 1,
      name: 'Curl',
      muscleGroup: MuscleGroup.biceps,
      isRequiredReps: true,
      isRequiredWeight: false,
      isRequiredTime: false,
      isRequiredDistance: false,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    final firstState = SetUiState(
      reps: '10',
      isChecked: false,
      isSkipped: false,
    );
    final secondState = SetUiState(
      reps: '10',
      isChecked: false,
      isSkipped: false,
    );
    addTearDown(firstState.dispose);
    addTearDown(secondState.dispose);

    SetWidget row(int id, int number, SetUiState state) => SetWidget(
          key: ValueKey(id),
          setData: SetData(
            completed: CompletedSet(id: id, completedExerciseId: 1),
          ),
          movement: movement,
          setNum: number,
          isLastSet: number == 2,
          isExSkipped: false,
          isLocked: false,
          isChecked: false,
          isSkipped: false,
          state: state,
          onTimerReset: () {},
          onToggle: (_) async {},
          onSkip: () async {},
          onDelete: () async {},
        );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          row(1, 1, firstState),
          row(2, 2, secondState),
        ]),
      ),
    ));

    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pump();

    expect(firstState.repsCtrl.text, '7');
    expect(secondState.repsCtrl.text, '10');
  });
}
