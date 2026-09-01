import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/screens/settings/ai_settings_screen.dart';

import 'support/test_app.dart';

void main() {
  setUp(initializeTestPreferences);

  testWidgets('AI settings renders under the real app theme', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(home: const AiSettingsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('AI Recommendations'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Check Balance'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('History Context'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
