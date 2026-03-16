import 'package:workmanager/workmanager.dart';

class BackupScheduler {
  static const _uniqueName = 'periodic-backup';
  static const _taskName = 'backupTask';

  /// Schedule (or re-schedule) the daily backup to run at [hour]:[minute].
  /// Replaces any existing scheduled backup.
  static Future<void> schedule(int hour, int minute) async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 24),
      initialDelay: next.difference(now),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_uniqueName);
  }
}
