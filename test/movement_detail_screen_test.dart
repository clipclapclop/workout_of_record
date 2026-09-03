import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/screens/movement_detail_screen.dart';

import 'support/test_app.dart';

void main() {
  Finder fieldWithLabel(String label) =>
      find.widgetWithText(TextFormField, label);

  testWidgets('movement switch changes are guarded and can be reverted', (
    tester,
  ) async {
    await initializeTestPreferences();
    const movement = Movement(
      id: 1,
      name: 'Pull-up',
      muscleGroup: MuscleGroup.back,
      isRequiredReps: true,
      isRequiredWeight: true,
      isRequiredTime: false,
      isRequiredDistance: false,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 1,
    );

    await tester.pumpWidget(
      buildTestApp(home: const MovementDetailScreen(movement: movement)),
    );
    await tester.pumpAndSettle();

    final reps = find.widgetWithText(SwitchListTile, 'Reps');
    await tester.tap(reps);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    await tester.tap(reps);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('invalid movement stays open when dialog Save is chosen', (
    tester,
  ) async {
    await initializeTestPreferences();
    await tester.pumpWidget(
      buildTestApp(home: const MovementDetailScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(fieldWithLabel('Sub-muscle Group (optional)'), 'Arm');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pump();

    expect(find.byType(MovementDetailScreen), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets(
    'movement numbers must be finite while assisted minimums remain valid',
    (tester) async {
      await initializeTestPreferences();
      const movement = Movement(
        id: 1,
        name: 'Assisted Pull-up',
        minWeight: -50,
        weightDelta: 5,
        muscleGroup: MuscleGroup.back,
        isRequiredReps: true,
        isRequiredWeight: true,
        isRequiredTime: false,
        isRequiredDistance: false,
        category: MovementCategory.resistance,
        bodyweightLoadFraction: 1,
      );

      await tester.pumpWidget(
        buildTestApp(home: const MovementDetailScreen(movement: movement)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final minWeight = fieldWithLabel('Min Weight (optional)');
      final weightStep = fieldWithLabel('Weight Step (optional)');
      final bodyweight = fieldWithLabel('Bodyweight load contribution');
      expect(minWeight, findsOneWidget);
      expect(weightStep, findsOneWidget);
      expect(bodyweight, findsOneWidget);

      await tester.enterText(minWeight, 'NaN');
      await tester.enterText(weightStep, 'Infinity');
      await tester.enterText(bodyweight, 'NaN');
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pump();

      expect(find.text('Enter a finite number'), findsOneWidget);
      expect(find.text('Enter a number greater than 0'), findsOneWidget);
      expect(find.text('Enter a finite number from 0 to 1'), findsOneWidget);

      await tester.enterText(minWeight, '-75');
      await tester.enterText(weightStep, '2.5');
      await tester.enterText(bodyweight, '0.8');
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
    },
  );
}
