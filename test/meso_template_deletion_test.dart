import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/template_data.dart';
import 'package:workout_of_record/screens/meso_template_list_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('used template deletion shows a clear explanation',
      (tester) async {
    await initializeTestPreferences();
    final template = MesoTemplate(
      id: 42,
      name: 'Used template',
      createdAt: DateTime(2026, 9, 3),
    );
    await tester.pumpWidget(
      buildTestApp(
        home: MesoTemplateListScreen(
          loadTemplates: () async => [
            MesoTemplateWithHistory(template: template, pastMesos: const []),
          ],
          deleteTemplate: (_) async => throw const TemplateInUseException(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Template actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This template has been used by a mesocycle and cannot be deleted.',
      ),
      findsOneWidget,
    );
    expect(find.text('Used template'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
