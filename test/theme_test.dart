import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/theme.dart';

import 'support/test_app.dart';

void main() {
  test('themes use built-in Roboto and preserve component typography', () {
    final dark = AppTheme.dark();
    final light = AppTheme.light();
    final filled = dark.filledButtonTheme.style!.textStyle!.resolve({})!;
    final outlined = dark.outlinedButtonTheme.style!.textStyle!.resolve({})!;
    final text = dark.textButtonTheme.style!.textStyle!.resolve({})!;
    final segmented = dark.segmentedButtonTheme.style!.textStyle!.resolve({})!;

    expect(dark.textTheme.bodyMedium!.fontFamily, 'Roboto');
    expect(light.textTheme.bodyMedium!.fontFamily, 'Roboto');
    expect(dark.appBarTheme.titleTextStyle!.fontFamily, 'Roboto');
    expect(dark.appBarTheme.titleTextStyle!.fontSize, 20);
    expect(dark.appBarTheme.titleTextStyle!.fontWeight, FontWeight.w600);
    expect(
      (filled.fontFamily, filled.fontSize, filled.fontWeight),
      ('Roboto', 15, FontWeight.w600),
    );
    expect(
      (outlined.fontFamily, outlined.fontSize, outlined.fontWeight),
      ('Roboto', 15, FontWeight.w500),
    );
    expect(
      (text.fontFamily, text.fontSize, text.fontWeight),
      ('Roboto', 14, FontWeight.w500),
    );
    expect(
      (segmented.fontFamily, segmented.fontSize, segmented.fontWeight),
      ('Roboto', 13, FontWeight.w500),
    );
  });

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
