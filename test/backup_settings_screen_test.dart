import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/screens/settings/backup_settings_screen.dart';

import 'support/test_app.dart';

void main() {
  setUp(() async {
    await initializeTestPreferences();
  });

  testWidgets('restore is available when backup creation is disabled',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(home: const BackupSettingsScreen()),
    );

    expect(find.text('Restore from Backup'), findsOneWidget);
    expect(
      find.textContaining('Enabling backups is not required.'),
      findsOneWidget,
    );
    expect(find.text('Back Up Now'), findsNothing);
  });

  testWidgets('backup creation cannot be saved without a destination',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(home: const BackupSettingsScreen()),
    );

    await tester.tap(find.text('Enable Backups'));
    await tester.pump();

    expect(
      find.text('Choose a folder before saving backup settings.'),
      findsOneWidget,
    );
    final autoBackupTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Backup on workout finish'),
    );
    expect(autoBackupTile.onChanged, isNull);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(
      find.text('Choose a backup folder before enabling backups.'),
      findsOneWidget,
    );
    expect(find.byType(BackupSettingsScreen), findsOneWidget);
    expect(AppPreferences.getBackupEnabled(), isFalse);
    expect(AppPreferences.getAutoBackupEnabled(), isFalse);
  });
}
