import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/workout_data.dart';
import 'package:workout_of_record/widgets/set_ui_state.dart';
import 'package:workout_of_record/widgets/set_widget.dart';

void main() {
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
