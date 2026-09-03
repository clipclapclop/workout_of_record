import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/screens/notes_screen.dart';
import 'package:workout_of_record/widgets/app_nav_menu.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('app-menu navigation lets changed notes keep editing', (
    tester,
  ) async {
    await _openNotes(tester, initialNotes: 'Original note');

    await tester.enterText(find.byType(TextField), 'Changed note');
    await tester.tap(find.byType(PopupMenuButton<AppScreen>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(AppPreferences.getNotes(), 'Original note');

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text('Changed note'), findsOneWidget);
    expect(AppPreferences.getNotes(), 'Original note');
  });

  testWidgets('reverting notes allows system back without a prompt', (
    tester,
  ) async {
    await _openNotes(tester, initialNotes: 'Original note');

    await tester.enterText(find.byType(TextField), 'Changed note');
    await tester.enterText(find.byType(TextField), 'Original note');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.text('Launcher'), findsOneWidget);
    expect(AppPreferences.getNotes(), 'Original note');
  });

  testWidgets('system back can save changed notes before leaving', (
    tester,
  ) async {
    await _openNotes(tester, initialNotes: 'Original note');

    await tester.enterText(find.byType(TextField), 'Changed note');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    expect(find.text('Launcher'), findsOneWidget);
    expect(AppPreferences.getNotes(), 'Changed note');
  });

  testWidgets('system back can discard changed notes', (tester) async {
    await _openNotes(tester, initialNotes: 'Original note');

    await tester.enterText(find.byType(TextField), 'Changed note');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Launcher'), findsOneWidget);
    expect(AppPreferences.getNotes(), 'Original note');
  });
}

Future<void> _openNotes(
  WidgetTester tester, {
  required String initialNotes,
}) async {
  await initializeTestPreferences({'notes': initialNotes});
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
                  MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
                ),
                child: const Text('Open notes'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open notes'));
  await tester.pumpAndSettle();
}
