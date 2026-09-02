import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/screens/profile_screen.dart';

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
