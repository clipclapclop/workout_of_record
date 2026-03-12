import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';

class BackupService {
  static const _dbFileName = 'workout_of_record.sqlite';
  static const _settingsFileName = 'settings.json';
  static const zipFileName = 'workout_of_record.zip';

  static Future<void> backup(String dirPath) async {
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

    final destZip = File(p.join(dirPath, zipFileName));
    await destZip.writeAsBytes(zipBytes);

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

    for (final file in archive) {
      if (!file.isFile) continue;
      final data = file.content as List<int>;
      if (file.name == _dbFileName) {
        await File(p.join(docsDir.path, _dbFileName)).writeAsBytes(data);
      } else if (file.name == _settingsFileName) {
        final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        await _applySettingsJson(json);
      }
    }
  }

  static Map<String, dynamic> _buildSettingsJson() {
    return {
      'dateOfBirth': AppPreferences.getDateOfBirth()?.toIso8601String(),
      'weight': AppPreferences.getWeight(),
      'trainingGoal': AppPreferences.getTrainingGoal()?.name,
      'calorieState': AppPreferences.getCalorieState()?.name,
      'aiEnabled': AppPreferences.getAiEnabled(),
      'unitsMetric': AppPreferences.getUnitsMetric(),
      'hasSeenProfilePrompt': AppPreferences.hasSeenProfilePrompt(),
    };
  }

  static Future<void> _applySettingsJson(Map<String, dynamic> json) async {
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
  }
}
