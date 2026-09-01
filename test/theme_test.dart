import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('themed buttons can size themselves inside a row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Row(
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final button in [
      find.byType(OutlinedButton),
      find.byType(FilledButton),
    ]) {
      final size = tester.getSize(button);
      expect(size.width, lessThan(360));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
