import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/widgets/empty_workout_view.dart';

void main() {
  testWidgets('empty workout offers add and finish actions', (tester) async {
    var addPressed = false;
    var finishPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyWorkoutView(
            onAddExercise: () => addPressed = true,
            onFinishWorkout: () => finishPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Finish Workout'), findsOneWidget);

    await tester.tap(find.text('Add Exercise'));
    await tester.tap(find.text('Finish Workout'));

    expect(addPressed, isTrue);
    expect(finishPressed, isTrue);
  });
}
