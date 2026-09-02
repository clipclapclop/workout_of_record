import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/workout_data.dart';
import 'package:workout_of_record/widgets/exercise_widget.dart';
import 'package:workout_of_record/widgets/set_ui_state.dart';

void main() {
  late SetUiState setState;

  setUp(() {
    setState = SetUiState(
      reps: '8',
      weight: '40',
      isChecked: true,
      isSkipped: false,
    );
  });

  tearDown(() => setState.dispose());

  ExerciseWidget buildExercise({
    required bool skipped,
    required bool started,
    required VoidCallback? onReplace,
    required VoidCallback onAdd,
    void Function(SetData)? onTimerReset,
  }) {
    final movement = Movement(
      id: 1,
      name: 'Test Curl',
      muscleGroup: MuscleGroup.biceps,
      isRequiredReps: true,
      isRequiredWeight: true,
      isRequiredTime: false,
      isRequiredDistance: false,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    final completedExercise = CompletedExercise(
      id: 1,
      completedWorkoutId: 1,
      movementId: movement.id,
      orderIndex: 0,
      persistence: Persistence.persistent,
      skipReason: skipped ? SkipReason.time : null,
      autoProgress: true,
    );
    final set = SetData(
      completed: const CompletedSet(id: 1, completedExerciseId: 1),
    );

    return ExerciseWidget(
      exercise: ExerciseData(
        completed: completedExercise,
        movement: movement,
        sets: [set],
      ),
      isActive: false,
      isExSkipped: skipped,
      isExLocked: false,
      allSetsDone: started && !skipped,
      showPostExReopen: false,
      anySetChecked: started && !skipped,
      showPostMgReopen: false,
      mgLabel: 'Biceps',
      persistence: Persistence.persistent,
      setStates: {1: setState},
      onTimerReset: onTimerReset ?? (_) {},
      onShowPostExerciseSheet: () async {},
      onShowPostMuscleGroupSheet: () async {},
      onShowExerciseSkipSheet: () async {},
      onUnskipExercise: () async {},
      onAddSet: () async {},
      onToggleSet: (_, _) async {},
      onShowSetSkipSheet: (_) async {},
      onDeleteSet: (_) async {},
      onTogglePersistence: () {},
      onReplace: onReplace,
      onAddExercise: onAdd,
      onShowMovementHistorySheet: () {},
      onWeightChanged: (_, _) {},
      onDistanceChanged: (_, _) {},
      onEditNote: () {},
    );
  }

  Future<void> pumpExercise(
    WidgetTester tester, {
    required bool skipped,
    required bool started,
    required VoidCallback? onReplace,
    required VoidCallback onAdd,
    void Function(SetData)? onTimerReset,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildExercise(
            skipped: skipped,
            started: started,
            onReplace: onReplace,
            onAdd: onAdd,
            onTimerReset: onTimerReset,
          ),
        ),
      ),
    );
  }

  testWidgets('timer reset identifies the interacted set', (tester) async {
    int? interactedSetId;
    await pumpExercise(
      tester,
      skipped: false,
      started: false,
      onReplace: () {},
      onAdd: () {},
      onTimerReset: (setData) => interactedSetId = setData.completed.id,
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNotNull);
    checkbox.onChanged!(true);

    expect(interactedSetId, 1);
  });

  testWidgets('completed exercise offers add but not replace', (tester) async {
    var added = false;
    await pumpExercise(
      tester,
      skipped: false,
      started: true,
      onReplace: null,
      onAdd: () => added = true,
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Replace'), findsNothing);
    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    expect(added, isTrue);
  });

  testWidgets('skipped exercise offers add but not replace', (tester) async {
    await pumpExercise(
      tester,
      skipped: true,
      started: false,
      onReplace: null,
      onAdd: () {},
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Replace'), findsNothing);
  });

  testWidgets('untouched exercise offers replace and add', (tester) async {
    await pumpExercise(
      tester,
      skipped: false,
      started: false,
      onReplace: () {},
      onAdd: () {},
    );

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text('Replace'), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
  });
}
