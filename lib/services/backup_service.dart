import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_preferences.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import 'saf_service.dart';

class BackupService {
  static const _dbFileName = 'workout_of_record.sqlite';
  static const _settingsFileName = 'settings.json';
  static const zipFileName = 'workout_of_record.zip';

  /// Builds the backup zip and returns raw bytes without writing to disk.
  static Future<Uint8List> buildBackupBytes() async {
    // Flush WAL data into the main database file so the backup is complete.
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, _dbFileName));
    if (!await dbFile.exists()) throw Exception('Database file not found');

    final dbBytes = await dbFile.readAsBytes();
    final settingsBytes = utf8.encode(jsonEncode(_buildSettingsJson()));

    final archive = Archive();
    archive.addFile(ArchiveFile(_dbFileName, dbBytes.length, dbBytes));
    archive.addFile(ArchiveFile(_settingsFileName, settingsBytes.length, settingsBytes));

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to create ZIP');
    return Uint8List.fromList(zipBytes);
  }

  /// Writes backup zip to the user-chosen SAF folder at [folderUri].
  /// Used by both "Backup Now" and is mirrored natively by [SafBackupWorker]
  /// for scheduled auto-backup.
  static Future<void> backup(String folderUri) async {
    final zipBytes = await buildBackupBytes();
    await SafService.writeFile(folderUri, zipBytes);
    await AppPreferences.setLastBackupTimestamp(DateTime.now());
  }

  static Future<void> restore(String zipPath) async {
    final zipBytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final hasDb = archive.any((f) => f.name == _dbFileName);
    final hasSettings = archive.any((f) => f.name == _settingsFileName);
    if (!hasDb || !hasSettings) {
      throw Exception('Invalid backup: missing required files');
    }

    final docsDir = await getApplicationDocumentsDirectory();

    // Close the active Drift connection so the file isn't locked and
    // WAL data isn't replayed on top of the restored database.
    await db.close();

    for (final file in archive) {
      if (!file.isFile) continue;
      final data = file.content as List<int>;
      if (file.name == _dbFileName) {
        final dbPath = p.join(docsDir.path, _dbFileName);
        // Delete WAL/SHM journal files — if left behind, SQLite replays
        // the old WAL on next open, reverting the restored data.
        final wal = File('$dbPath-wal');
        final shm = File('$dbPath-shm');
        if (await wal.exists()) await wal.delete();
        if (await shm.exists()) await shm.delete();
        await File(dbPath).writeAsBytes(data);
      } else if (file.name == _settingsFileName) {
        final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        await _applySettingsJson(json);
      }
    }
  }

  static Map<String, dynamic> _buildSettingsJson() {
    return {
      'currentMesocycleId': AppPreferences.getCurrentMesocycleId(),
      'currentCompletedWorkoutId': AppPreferences.getCurrentCompletedWorkoutId(),
      'dateOfBirth': AppPreferences.getDateOfBirth()?.toIso8601String(),
      'weight': AppPreferences.getWeight(),
      'trainingGoal': AppPreferences.getTrainingGoal()?.name,
      'calorieState': AppPreferences.getCalorieState()?.name,
      'aiEnabled': AppPreferences.getAiEnabled(),
      'unitsMetric': AppPreferences.getUnitsMetric(),
      'hasSeenProfilePrompt': AppPreferences.hasSeenProfilePrompt(),
      'notes': AppPreferences.getNotes(),
    };
  }

  static Future<void> _applySettingsJson(Map<String, dynamic> json) async {
    // Restore acceleration pointers so the app resumes with the correct
    // mesocycle / in-progress workout from the backed-up database.
    await AppPreferences.setCurrentMesocycleId(json['currentMesocycleId'] as int?);
    await AppPreferences.setCurrentCompletedWorkoutId(
        json['currentCompletedWorkoutId'] as int?);

    final dob = json['dateOfBirth'] as String?;
    await AppPreferences.setDateOfBirth(dob == null ? null : DateTime.parse(dob));

    final weight = json['weight'];
    await AppPreferences.setWeight(weight == null ? null : (weight as num).toDouble());

    final trainingGoal = json['trainingGoal'] as String?;
    await AppPreferences.setTrainingGoal(
      trainingGoal == null ? null : TrainingGoal.values.byName(trainingGoal),
    );

    final calorieState = json['calorieState'] as String?;
    await AppPreferences.setCalorieState(
      calorieState == null ? null : CalorieState.values.byName(calorieState),
    );

    if (json['aiEnabled'] != null) {
      await AppPreferences.setAiEnabled(json['aiEnabled'] as bool);
    }
    if (json['unitsMetric'] != null) {
      await AppPreferences.setUnitsMetric(json['unitsMetric'] as bool);
    }
    if (json['hasSeenProfilePrompt'] != null) {
      await AppPreferences.setHasSeenProfilePrompt(json['hasSeenProfilePrompt'] as bool);
    }
    if (json['notes'] != null) {
      await AppPreferences.setNotes(json['notes'] as String);
    }
  }
}
