import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/template_data.dart';
import 'package:workout_of_record/screens/meso_template_builder_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('reverted template edits and cancelled dialogs stay clean',
      (tester) async {
    final data = _templateData();
    await _openBuilder(tester, data);

    final nameField = find.byType(TextField);
    await tester.enterText(nameField, 'Changed template');
    await tester.enterText(nameField, 'Original template');

    await tester.tap(find.byTooltip('Add day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.text('Launcher'), findsOneWidget);
  });

  testWidgets('nested template changes support keep editing and discard',
      (tester) async {
    final data = _templateData();
    await _openBuilder(tester, data);

    await tester.tap(find.byType(Switch));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(MesoTemplateBuilderScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Launcher'), findsOneWidget);
  });
}

Future<void> _openBuilder(
  WidgetTester tester,
  MesoTemplateData data,
) async {
  await initializeTestPreferences();
  final movement = data.days.single.exercises.single.movement;
  await tester.pumpWidget(
    buildTestApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Text('Launcher'),
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => MesoTemplateBuilderScreen(
                      existing: data,
                      isNew: false,
                      loadMovements: () async => [movement],
                    ),
                  ),
                ),
                child: const Text('Open builder'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open builder'));
  await tester.pumpAndSettle();
}

MesoTemplateData _templateData() {
  const movement = Movement(
    id: 1,
    name: 'Curl',
    muscleGroup: MuscleGroup.biceps,
    isRequiredReps: true,
    isRequiredWeight: true,
    isRequiredTime: false,
    isRequiredDistance: false,
    category: MovementCategory.resistance,
    bodyweightLoadFraction: 0,
  );
  return MesoTemplateData(
    template: MesoTemplate(
      id: 4,
      name: 'Original template',
      createdAt: DateTime(2026),
    ),
    days: const [
      WorkoutDayData(
        template: WorkoutTemplate(
          id: 5,
          weekTemplateId: 4,
          name: 'Monday',
          isRestDay: false,
          dayIndex: 0,
        ),
        exercises: [
          ExerciseDayEntry(movement: movement, autoProgress: true),
        ],
      ),
    ],
  );
}
