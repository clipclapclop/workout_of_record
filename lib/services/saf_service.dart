import 'package:flutter/services.dart';

class SafService {
  static const _channel = MethodChannel('workout_of_record/saf');

  /// Opens the system folder picker. Returns the persistent SAF URI string,
  /// or null if the user cancelled.
  static Future<String?> pickFolder() =>
      _channel.invokeMethod<String>('pickFolder');

  /// Writes [bytes] as workout_of_record.zip into the SAF folder at [folderUri].
  static Future<void> writeFile(String folderUri, Uint8List bytes) =>
      _channel.invokeMethod('writeFile', {'uri': folderUri, 'bytes': bytes});

  /// Schedules the native backup worker to run daily at [hour]:[minute].
  static Future<void> scheduleBackup(int hour, int minute) =>
      _channel.invokeMethod('scheduleBackup', {'hour': hour, 'minute': minute});

  /// Cancels the scheduled native backup worker.
  static Future<void> cancelBackup() =>
      _channel.invokeMethod('cancelBackup');
}
