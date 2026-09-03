import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/widgets/unsaved_changes_dialog.dart';

import 'support/test_app.dart';

void main() {
  setUp(initializeTestPreferences);

  testWidgets('unsaved dialog keeps edits or discards them as chosen', (
    tester,
  ) async {
    final savedValues = <bool>[];
    _usePhoneSize(tester);
    await _openTestSettings(tester, onSave: savedValues.add);

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
    expect(find.byType(_TestSettingsScreen), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(savedValues, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(_TestSettingsScreen), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
    expect(savedValues, isEmpty);
  });

  testWidgets('unsaved dialog saves before leaving settings', (tester) async {
    final savedValues = <bool>[];
    _usePhoneSize(tester);
    await _openTestSettings(tester, onSave: savedValues.add);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    expect(find.byType(_TestSettingsScreen), findsNothing);
    expect(savedValues, [true]);
  });

  testWidgets('unsaved dialog actions remain readable at large text', (
    tester,
  ) async {
    _usePhoneSize(tester);
    await _openTestSettings(tester, textScale: 1.5, onSave: (_) {});

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

class _TestSettingsScreen extends StatefulWidget {
  const _TestSettingsScreen({required this.onSave});

  final ValueChanged<bool> onSave;

  @override
  State<_TestSettingsScreen> createState() => _TestSettingsScreenState();
}

class _TestSettingsScreenState extends State<_TestSettingsScreen> {
  bool _value = false;
  bool _savedValue = false;

  Future<bool> _onPop() async {
    if (_value == _savedValue) return true;
    final action = await showUnsavedChangesDialog(context);
    if (action == UnsavedChangesAction.save) {
      _save();
      return true;
    }
    return action == UnsavedChangesAction.discard;
  }

  void _save() {
    _savedValue = _value;
    widget.onSave(_value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onPop();
        if (shouldLeave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Test settings')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: FilledButton(
              onPressed: () {
                _save();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ),
        body: SwitchListTile(
          title: const Text('Test setting'),
          value: _value,
          onChanged: (value) => setState(() => _value = value),
        ),
      ),
    );
  }
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

Future<void> _openTestSettings(
  WidgetTester tester, {
  required ValueChanged<bool> onSave,
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
                  builder: (_) => _TestSettingsScreen(onSave: onSave),
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
