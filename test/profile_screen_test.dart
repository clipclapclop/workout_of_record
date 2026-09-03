import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/screens/profile_screen.dart';
import 'package:workout_of_record/screens/settings_screen.dart';
import 'package:workout_of_record/screens/workout_screen.dart';
import 'package:workout_of_record/widgets/app_nav_menu.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('profile preserves legacy weight and labels it in pounds', (
    tester,
  ) async {
    await initializeTestPreferences({
      'profile_weight_kg': 187.5,
      'settings_units_metric': true,
    });

    await tester.pumpWidget(buildTestApp(home: const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('187.5'), findsOneWidget);
    expect(find.text('lbs'), findsOneWidget);
    expect(find.text('kg'), findsNothing);
  });

  testWidgets('profile rejects unusable numbers without replacing saved data', (
    tester,
  ) async {
    await initializeTestPreferences({'profile_weight_lbs': 187.5});

    await tester.pumpWidget(buildTestApp(home: const ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '187.5'), 'NaN');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Years lifting / exercising'),
      '-1',
    );
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
    await tester.pump();

    expect(find.text('Enter a number greater than 0'), findsOneWidget);
    expect(find.text('Enter a number of 0 or more'), findsOneWidget);
    expect(AppPreferences.getWeight(), 187.5);
  });

  testWidgets('dialog Save continues to the app-menu destination', (
    tester,
  ) async {
    await initializeTestPreferences({'profile_weight_lbs': 187.5});

    await tester.pumpWidget(buildTestApp(home: const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '187.5'), '190');

    await tester.tap(find.byType(PopupMenuButton<AppScreen>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    expect(AppPreferences.getWeight(), 190);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('system-back Save returns to the mounted active workout', (
    tester,
  ) async {
    await initializeTestPreferences({'profile_weight_lbs': 187.5});
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (rootContext) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push(
                rootContext,
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: WorkoutScreen.routeName),
                  builder: (workoutContext) => Scaffold(
                    body: Column(
                      children: [
                        const Text('Mounted workout'),
                        FilledButton(
                          onPressed: () => Navigator.push(
                            workoutContext,
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileScreen(
                                activeWorkoutId: 42,
                                activeWorkoutName: 'Active workout',
                              ),
                            ),
                          ),
                          child: const Text('Open profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Open workout'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '187.5'), '190');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pumpAndSettle();

    expect(AppPreferences.getWeight(), 190);
    expect(find.text('Mounted workout'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('invalid profile stays open when dialog Save is chosen', (
    tester,
  ) async {
    await initializeTestPreferences({'profile_weight_lbs': 187.5});

    await tester.pumpWidget(buildTestApp(home: const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '187.5'), 'NaN');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await tester.pump();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Enter a number greater than 0'), findsOneWidget);
    expect(AppPreferences.getWeight(), 187.5);
  });

  test('legacy zero profile weight is treated as blank', () async {
    await initializeTestPreferences({'profile_weight_lbs': 0.0});

    expect(AppPreferences.getWeight(), isNull);
  });

  test(
    'profile persistence rejects non-positive and non-finite weight',
    () async {
      await initializeTestPreferences();

      expect(() => AppPreferences.setWeight(0), throwsArgumentError);
      expect(() => AppPreferences.setWeight(-1), throwsArgumentError);
      expect(() => AppPreferences.setWeight(double.nan), throwsArgumentError);
      expect(
        () => AppPreferences.setWeight(double.infinity),
        throwsArgumentError,
      );

      await AppPreferences.setWeight(180);
      expect(AppPreferences.getWeight(), 180);
    },
  );
}
