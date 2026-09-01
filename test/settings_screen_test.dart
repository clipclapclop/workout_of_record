import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/screens/settings_screen.dart';

import 'support/test_app.dart';

void main() {
  setUp(initializeTestPreferences);

  testWidgets('settings omits the removed unit preferences page',
      (tester) async {
    await tester.pumpWidget(buildTestApp(home: const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('General'), findsNothing);
    expect(find.text('Metric units'), findsNothing);
    expect(find.text('Rest Timer'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsOneWidget);
  });
}
