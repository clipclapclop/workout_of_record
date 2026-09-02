import 'package:flutter/services.dart';

class SafWriteException implements Exception {
  const SafWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SafService {
  static const _channel = MethodChannel('workout_of_record/saf');

  /// Opens the system folder picker. Returns the persistent SAF URI string,
  /// or null if the user cancelled.
  static Future<String?> pickFolder() =>
      _channel.invokeMethod<String>('pickFolder');

  /// Returns true if the SAF folder at [folderUri] is still accessible and
  /// writable. Returns false if permission was revoked or the folder was deleted.
  static Future<bool> checkFolder(String folderUri) async =>
      await _channel.invokeMethod<bool>('checkFolder', {'uri': folderUri}) ??
      false;

  /// Safely replaces workout_of_record.zip in the SAF folder at [folderUri].
  /// The Android side stages and verifies the bytes before changing the fixed file.
  static Future<void> writeFile(String folderUri, Uint8List bytes) async {
    try {
      await _channel.invokeMethod('writeFile', {
        'uri': folderUri,
        'bytes': bytes,
      });
    } on PlatformException catch (error) {
      throw SafWriteException(
        error.message ?? 'The backup file could not be written safely.',
      );
    }
  }

  /// Appends [bytes] to [fileName] in the SAF folder at [folderUri].
  /// Creates the file if it doesn't exist.
  static Future<void> appendToFile(
    String folderUri,
    String fileName,
    Uint8List bytes,
  ) => _channel.invokeMethod('appendToFile', {
    'uri': folderUri,
    'fileName': fileName,
    'bytes': bytes,
  });

  /// Schedules the native backup worker to run daily at [hour]:[minute].
  static Future<void> scheduleBackup(int hour, int minute) =>
      _channel.invokeMethod('scheduleBackup', {'hour': hour, 'minute': minute});

  /// Cancels the scheduled native backup worker.
  static Future<void> cancelBackup() => _channel.invokeMethod('cancelBackup');
}
