import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/screens/settings/general_settings_screen.dart';

import 'support/test_app.dart';

void main() {
  setUp(initializeTestPreferences);

  testWidgets('unsaved dialog keeps edits or discards them as chosen', (
    tester,
  ) async {
    _usePhoneSize(tester);
    await _openGeneralSettings(tester);

    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Save')).width,
      greaterThan(300),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    for (final label in ['Keep editing', 'Discard', 'Save']) {
      expect(_lineCount(tester, label), 1);
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(GeneralSettingsScreen), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(AppPreferences.getUnitsMetric(), isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(GeneralSettingsScreen), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
    expect(AppPreferences.getUnitsMetric(), isFalse);
  });

  testWidgets('unsaved dialog saves before leaving settings', (tester) async {
    _usePhoneSize(tester);
    await _openGeneralSettings(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    expect(find.byType(GeneralSettingsScreen), findsNothing);
    expect(AppPreferences.getUnitsMetric(), isTrue);
  });

  testWidgets('unsaved dialog actions remain readable at large text', (
    tester,
  ) async {
    _usePhoneSize(tester);
    await _openGeneralSettings(tester, textScale: 1.5);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(_lineCount(tester, 'Keep editing'), lessThanOrEqualTo(2));
    expect(_lineCount(tester, 'Discard'), 1);
    expect(_lineCount(tester, 'Save'), 1);
    expect(tester.takeException(), isNull);
  });
}

int _lineCount(WidgetTester tester, String label) {
  final text = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(label),
  );
  expect(text, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(text);
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: label.length),
      )
      .length;
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openGeneralSettings(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      textScale: textScale,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const GeneralSettingsScreen(),
                ),
              ),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open settings'));
  await tester.pumpAndSettle();
}
