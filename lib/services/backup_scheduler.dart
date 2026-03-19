import 'saf_service.dart';

class BackupScheduler {
  static Future<void> schedule(int hour, int minute) =>
      SafService.scheduleBackup(hour, minute);

  static Future<void> cancel() => SafService.cancelBackup();
}
