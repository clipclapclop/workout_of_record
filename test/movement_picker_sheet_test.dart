import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/widgets/movement_picker_sheet.dart';

void main() {
  testWidgets('picker waits for the add action before closing', (tester) async {
    final addFinished = Completer<void>();
    var addStarted = false;
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

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMovementPickerSheet(
                context: context,
                allMovements: [movement],
                alreadyAdded: const {},
                onAdd: (_) async {
                  addStarted = true;
                  await addFinished.future;
                },
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Curl'));
    await tester.pump();

    expect(addStarted, isTrue);
    expect(find.text('Test Curl'), findsOneWidget);

    addFinished.complete();
    await tester.pumpAndSettle();

    expect(find.text('Test Curl'), findsNothing);
  });
}
