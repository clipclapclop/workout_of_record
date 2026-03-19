import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'screens/home_screen.dart';
import 'services/backup_scheduler.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
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
