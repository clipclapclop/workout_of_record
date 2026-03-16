import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app_preferences.dart';
import 'screens/home_screen.dart';
import 'services/backup_scheduler.dart';
import 'services/backup_service.dart';
import 'theme.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'backupTask') {
      await AppPreferences.init();
      final dirPath = AppPreferences.getBackupDirectoryPath();
      if (dirPath != null) {
        await BackupService.backup(dirPath);
      }
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  await Workmanager().initialize(callbackDispatcher);
  if (AppPreferences.getBackupEnabled() && AppPreferences.getAutoBackupEnabled()) {
    await BackupScheduler.schedule(
      AppPreferences.getBackupHour(),
      AppPreferences.getBackupMinute(),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout of Record',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
