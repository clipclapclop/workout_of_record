import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/screens/profile_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('profile preserves legacy weight and labels it in pounds',
      (tester) async {
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
}
