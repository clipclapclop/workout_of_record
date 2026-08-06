import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' hide ZLibDecoder;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import 'saf_service.dart';

class BackupRestoreException implements Exception {
  const BackupRestoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupSettings {
  const BackupSettings({
    this.currentMesocycleId,
    this.currentCompletedWorkoutId,
    this.dateOfBirth,
    this.weight,
    this.trainingGoal,
    this.calorieState,
    this.aiEnabled = true,
    this.unitsMetric = false,
    this.hasSeenProfilePrompt = false,
    this.notes = '',
  });

  final int? currentMesocycleId;
  final int? currentCompletedWorkoutId;
  final DateTime? dateOfBirth;
  final double? weight;
  final TrainingGoal? trainingGoal;
  final CalorieState? calorieState;
  final bool aiEnabled;
  final bool unitsMetric;
  final bool hasSeenProfilePrompt;
  final String notes;

  static const _allowedKeys = {
    'currentMesocycleId',
    'currentCompletedWorkoutId',
    'dateOfBirth',
    'weight',
    'trainingGoal',
    'calorieState',
    'aiEnabled',
    'unitsMetric',
    'hasSeenProfilePrompt',
    'notes',
  };

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    final unknown = json.keys
        .where((key) => !_allowedKeys.contains(key))
        .toList();
    if (unknown.isNotEmpty) {
      throw BackupRestoreException(
        'Invalid backup settings: unsupported field "${unknown.first}".',
      );
    }

    int? positiveId(String key) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! int || value <= 0) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be a positive integer or null.',
        );
      }
      return value;
    }

    DateTime? date(String key) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! String) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be an ISO-8601 string or null.',
        );
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw BackupRestoreException(
          'Invalid backup settings: $key is not a valid ISO-8601 date.',
        );
      }
      return parsed;
    }

    double? finiteNumber(String key) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! num) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be a number or null.',
        );
      }
      final converted = value.toDouble();
      if (!converted.isFinite || converted < 0) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be a finite, non-negative number.',
        );
      }
      return converted;
    }

    T? enumValue<T extends Enum>(String key, List<T> values) {
      final value = json[key];
      if (value == null) {
        return null;
      }
      if (value is! String) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be a supported name or null.',
        );
      }
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
      throw BackupRestoreException(
        'Invalid backup settings: unsupported $key value "$value".',
      );
    }

    bool boolean(String key, bool defaultValue) {
      if (!json.containsKey(key)) return defaultValue;
      final value = json[key];
      if (value is! bool) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be true or false.',
        );
      }
      return value;
    }

    String string(String key, String defaultValue) {
      if (!json.containsKey(key)) return defaultValue;
      final value = json[key];
      if (value is! String) {
        throw BackupRestoreException(
          'Invalid backup settings: $key must be a string.',
        );
      }
      return value;
    }

    return BackupSettings(
      currentMesocycleId: positiveId('currentMesocycleId'),
      currentCompletedWorkoutId: positiveId('currentCompletedWorkoutId'),
      dateOfBirth: date('dateOfBirth'),
      weight: finiteNumber('weight'),
      trainingGoal: enumValue('trainingGoal', TrainingGoal.values),
      calorieState: enumValue('calorieState', CalorieState.values),
      aiEnabled: boolean('aiEnabled', true),
      unitsMetric: boolean('unitsMetric', false),
      hasSeenProfilePrompt: boolean('hasSeenProfilePrompt', false),
      notes: string('notes', ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentMesocycleId': currentMesocycleId,
    'currentCompletedWorkoutId': currentCompletedWorkoutId,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'weight': weight,
    'trainingGoal': trainingGoal?.name,
    'calorieState': calorieState?.name,
    'aiEnabled': aiEnabled,
    'unitsMetric': unitsMetric,
    'hasSeenProfilePrompt': hasSeenProfilePrompt,
    'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      other is BackupSettings &&
      other.currentMesocycleId == currentMesocycleId &&
      other.currentCompletedWorkoutId == currentCompletedWorkoutId &&
      other.dateOfBirth == dateOfBirth &&
      other.weight == weight &&
      other.trainingGoal == trainingGoal &&
      other.calorieState == calorieState &&
      other.aiEnabled == aiEnabled &&
      other.unitsMetric == unitsMetric &&
      other.hasSeenProfilePrompt == hasSeenProfilePrompt &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    currentMesocycleId,
    currentCompletedWorkoutId,
    dateOfBirth,
    weight,
    trainingGoal,
    calorieState,
    aiEnabled,
    unitsMetric,
    hasSeenProfilePrompt,
    notes,
  );
}

abstract interface class BackupSettingsStore {
  BackupSettings read();
  Future<void> write(BackupSettings settings);
}

class AppPreferencesBackupSettingsStore implements BackupSettingsStore {
  const AppPreferencesBackupSettingsStore();

  @override
  BackupSettings read() => BackupSettings(
    currentMesocycleId: AppPreferences.getCurrentMesocycleId(),
    currentCompletedWorkoutId: AppPreferences.getCurrentCompletedWorkoutId(),
    dateOfBirth: AppPreferences.getDateOfBirth(),
    weight: AppPreferences.getWeight(),
    trainingGoal: AppPreferences.getTrainingGoal(),
    calorieState: AppPreferences.getCalorieState(),
    aiEnabled: AppPreferences.getAiEnabled(),
    unitsMetric: AppPreferences.getUnitsMetric(),
    hasSeenProfilePrompt: AppPreferences.hasSeenProfilePrompt(),
    notes: AppPreferences.getNotes(),
  );

  @override
  Future<void> write(BackupSettings settings) async {
    await AppPreferences.setCurrentMesocycleId(settings.currentMesocycleId);
    await AppPreferences.setCurrentCompletedWorkoutId(
      settings.currentCompletedWorkoutId,
    );
    await AppPreferences.setDateOfBirth(settings.dateOfBirth);
    await AppPreferences.setWeight(settings.weight);
    await AppPreferences.setTrainingGoal(settings.trainingGoal);
    await AppPreferences.setCalorieState(settings.calorieState);
    await AppPreferences.setAiEnabled(settings.aiEnabled);
    await AppPreferences.setUnitsMetric(settings.unitsMetric);
    await AppPreferences.setHasSeenProfilePrompt(settings.hasSeenProfilePrompt);
    await AppPreferences.setNotes(settings.notes);

    if (read() != settings) {
      throw const BackupRestoreException(
        'The restored settings could not be saved.',
      );
    }
  }
}

abstract interface class DatabaseRestoreLifecycle {
  Map<String, List<String>> get expectedSchema;
  Future<void> checkpointAndClose();
  Future<void> reopenAfterFailure();
}

class AppDatabaseRestoreLifecycle implements DatabaseRestoreLifecycle {
  const AppDatabaseRestoreLifecycle();

  @override
  Map<String, List<String>> get expectedSchema => {
    for (final table in db.allTables)
      table.entityName: [for (final column in table.$columns) column.$name],
  };

  @override
  Future<void> checkpointAndClose() => checkpointAndCloseDatabaseForRestore();

  @override
  Future<void> reopenAfterFailure() => reopenDatabaseAfterFailedRestore();
}

abstract interface class RestoreFileOperations {
  Future<bool> exists(String path);
  Future<void> write(String path, List<int> bytes);
  Future<void> copy(String source, String destination);
  Future<void> rename(String source, String destination);
  Future<void> delete(String path);
}

class LocalRestoreFileOperations implements RestoreFileOperations {
  const LocalRestoreFileOperations();

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> write(String path, List<int> bytes) =>
      File(path).writeAsBytes(bytes, flush: true);

  @override
  Future<void> copy(String source, String destination) async {
    await File(source).copy(destination);
  }

  @override
  Future<void> rename(String source, String destination) async {
    await File(source).rename(destination);
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class BackupRestoreService {
  BackupRestoreService({
    required this.databasePath,
    required this.settingsStore,
    required this.databaseLifecycle,
    this.fileOperations = const LocalRestoreFileOperations(),
    this.databaseSizeLimit = maxDatabaseBytes,
    this.settingsSizeLimit = maxSettingsBytes,
  });

  static const databaseFileName = 'workout_of_record.sqlite';
  static const settingsFileName = 'settings.json';
  static const maxArchiveBytes = 256 * 1024 * 1024;
  static const maxDatabaseBytes = 256 * 1024 * 1024;
  static const maxSettingsBytes = 1024 * 1024;

  final String databasePath;
  final BackupSettingsStore settingsStore;
  final DatabaseRestoreLifecycle databaseLifecycle;
  final RestoreFileOperations fileOperations;
  final int databaseSizeLimit;
  final int settingsSizeLimit;

  bool _isRestoring = false;

  String get _stagedPath => '$databasePath.restore-stage';
  String get _rollbackPath => '$databasePath.restore-original';

  Future<void> restoreBytes(List<int> zipBytes) async {
    if (_isRestoring) {
      throw const BackupRestoreException(
        'A backup restore is already in progress.',
      );
    }
    _isRestoring = true;
    try {
      final prepared = _decodeAndValidateArchive(zipBytes);
      await _prepareStage(prepared.databaseBytes, prepared.settings);
      await _replaceLiveState(prepared.settings);
    } finally {
      _isRestoring = false;
    }
  }

  _PreparedBackup _decodeAndValidateArchive(List<int> zipBytes) {
    if (zipBytes.isEmpty || zipBytes.length > maxArchiveBytes) {
      throw const BackupRestoreException(
        'Invalid backup: the ZIP file is empty or too large.',
      );
    }

    Archive archive;
    late List<String> entryNames;
    try {
      final decoder = ZipDecoder();
      archive = decoder.decodeBytes(zipBytes);
      // Archive collapses duplicate names, so inspect the raw central directory
      // before relying on its file map.
      entryNames = [
        for (final header in decoder.directory.fileHeaders)
          header.file!.filename,
      ];
    } catch (_) {
      throw const BackupRestoreException(
        'Invalid backup: the ZIP file is malformed or corrupt.',
      );
    }

    final databaseEntryCount = entryNames
        .where((name) => name == databaseFileName)
        .length;
    final settingsEntryCount = entryNames
        .where((name) => name == settingsFileName)
        .length;

    if (databaseEntryCount == 0 || settingsEntryCount == 0) {
      throw const BackupRestoreException(
        'Invalid backup: required database or settings file is missing.',
      );
    }
    if (databaseEntryCount != 1 || settingsEntryCount != 1) {
      throw const BackupRestoreException(
        'Invalid backup: required files must not be duplicated.',
      );
    }

    final databaseEntry = archive.firstWhere(
      (file) => file.name == databaseFileName,
    );
    final settingsEntry = archive.firstWhere(
      (file) => file.name == settingsFileName,
    );
    if (entryNames.length != 2 ||
        archive.length != 2 ||
        !databaseEntry.isFile ||
        !settingsEntry.isFile) {
      throw const BackupRestoreException(
        'Invalid backup: only the two required root-level files are supported.',
      );
    }
    if (databaseEntry.size <= 0 || databaseEntry.size > databaseSizeLimit) {
      throw const BackupRestoreException(
        'Invalid backup: the database file is empty or too large.',
      );
    }
    if (settingsEntry.size <= 0 || settingsEntry.size > settingsSizeLimit) {
      throw const BackupRestoreException(
        'Invalid backup: the settings file is empty or too large.',
      );
    }

    try {
      final databaseBytes = _decodeEntryBounded(
        databaseEntry,
        databaseSizeLimit,
      );
      final settingsBytes = _decodeEntryBounded(
        settingsEntry,
        settingsSizeLimit,
      );
      return _PreparedBackup(databaseBytes, _decodeSettings(settingsBytes));
    } on BackupRestoreException {
      rethrow;
    } catch (_) {
      throw const BackupRestoreException(
        'Invalid backup: a required file is corrupt.',
      );
    }
  }

  List<int> _decodeEntryBounded(ArchiveFile entry, int limit) {
    final rawBytes = entry.rawContent?.toUint8List();
    if (rawBytes == null) {
      throw const BackupRestoreException(
        'Invalid backup: a required file has no content.',
      );
    }

    late Uint8List decoded;
    if (entry.compressionType == ArchiveFile.STORE) {
      if (rawBytes.length > limit) {
        throw const BackupRestoreException(
          'Invalid backup: an extracted file is too large.',
        );
      }
      decoded = Uint8List.fromList(rawBytes);
    } else if (entry.compressionType == ArchiveFile.DEFLATE) {
      final sink = _BoundedBytesSink(limit);
      final decoder = ZLibDecoder(raw: true).startChunkedConversion(sink);
      decoder.add(rawBytes);
      decoder.close();
      decoded = sink.bytes;
    } else {
      throw const BackupRestoreException(
        'Invalid backup: a required file uses unsupported compression.',
      );
    }

    if (decoded.length != entry.size || getCrc32(decoded) != entry.crc32) {
      throw const BackupRestoreException(
        'Invalid backup: a required file is corrupt.',
      );
    }
    return decoded;
  }

  BackupSettings _decodeSettings(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (decoded is! Map<String, dynamic>) {
        throw const BackupRestoreException(
          'Invalid backup settings: expected a JSON object.',
        );
      }
      return BackupSettings.fromJson(decoded);
    } on BackupRestoreException {
      rethrow;
    } on FormatException {
      throw const BackupRestoreException(
        'Invalid backup settings: the JSON is malformed.',
      );
    } catch (_) {
      throw const BackupRestoreException(
        'Invalid backup settings: the JSON could not be decoded.',
      );
    }
  }

  Future<void> _prepareStage(
    List<int> databaseBytes,
    BackupSettings settings,
  ) async {
    if (await fileOperations.exists(_rollbackPath)) {
      throw BackupRestoreException(
        'Restore cannot start because recovery data already exists at '
        '$_rollbackPath.',
      );
    }
    await fileOperations.delete(_stagedPath);
    try {
      await fileOperations.write(_stagedPath, databaseBytes);
      await _validateStagedDatabase(_stagedPath, settings);
    } catch (_) {
      await _deleteBestEffort(_stagedPath);
      rethrow;
    }
  }

  Future<void> _validateStagedDatabase(
    String path,
    BackupSettings settings,
  ) async {
    final initialVersion = await _readSchemaVersion(path);
    if (initialVersion < minimumRestorableSchemaVersion ||
        initialVersion > currentDatabaseSchemaVersion) {
      throw BackupRestoreException(
        'Incompatible backup database schema $initialVersion; this app '
        'supports $minimumRestorableSchemaVersion through '
        '$currentDatabaseSchemaVersion.',
      );
    }

    if (initialVersion < currentDatabaseSchemaVersion) {
      final migrationDatabase = AppDatabase.withExecutor(
        NativeDatabase(File(path)),
      );
      try {
        await migrationDatabase.customSelect('SELECT 1').get();
      } catch (_) {
        throw const BackupRestoreException(
          'Invalid backup database: migration to the current schema failed.',
        );
      } finally {
        await migrationDatabase.close();
      }
    }

    await _validateSqliteFile(path, settings);
  }

  Future<int> _readSchemaVersion(String path) async {
    try {
      final file = File(path);
      if (await file.length() < 64) {
        throw const BackupRestoreException(
          'Invalid backup database: the SQLite file is malformed or incompatible.',
        );
      }
      final handle = await file.open();
      late List<int> header;
      try {
        header = await handle.read(64);
      } finally {
        await handle.close();
      }
      const signature = [
        0x53,
        0x51,
        0x4c,
        0x69,
        0x74,
        0x65,
        0x20,
        0x66,
        0x6f,
        0x72,
        0x6d,
        0x61,
        0x74,
        0x20,
        0x33,
        0x00,
      ];
      for (var index = 0; index < signature.length; index++) {
        if (header[index] != signature[index]) {
          throw const BackupRestoreException(
            'Invalid backup database: the SQLite file is malformed or incompatible.',
          );
        }
      }
      final version = ByteData.sublistView(
        Uint8List.fromList(header),
      ).getUint32(60, Endian.big);
      if (version <= 0) {
        throw const BackupRestoreException(
          'Invalid backup database: missing schema version.',
        );
      }
      return version;
    } on BackupRestoreException {
      rethrow;
    } catch (_) {
      throw const BackupRestoreException(
        'Invalid backup database: the SQLite file is malformed or incompatible.',
      );
    }
  }

  Future<void> _validateSqliteFile(String path, BackupSettings settings) async {
    final candidate = AppDatabase.withExecutor(
      NativeDatabase(File(path), enableMigrations: false),
    );
    try {
      final integrity = await candidate
          .customSelect('PRAGMA integrity_check')
          .get();
      if (integrity.length != 1 || integrity.first.data.values.first != 'ok') {
        throw const BackupRestoreException(
          'Invalid backup database: SQLite integrity check failed.',
        );
      }
      if ((await candidate.customSelect('PRAGMA foreign_key_check').get())
          .isNotEmpty) {
        throw const BackupRestoreException(
          'Invalid backup database: related workout records are inconsistent.',
        );
      }

      await _validateExpectedSchema(candidate);
      await _validatePointers(candidate, settings);
    } on BackupRestoreException {
      rethrow;
    } catch (_) {
      throw const BackupRestoreException(
        'Invalid backup database: the SQLite file is malformed or incompatible.',
      );
    } finally {
      await candidate.close();
    }
  }

  Future<void> _validateExpectedSchema(AppDatabase candidate) async {
    for (final table in databaseLifecycle.expectedSchema.entries) {
      final tableName = _quoteIdentifier(table.key);
      final columns = table.value.map(_quoteIdentifier).join(', ');
      await candidate
          .customSelect('SELECT $columns FROM $tableName LIMIT 0')
          .get();
    }
  }

  Future<void> _validatePointers(
    AppDatabase candidate,
    BackupSettings settings,
  ) async {
    final mesocycleId = settings.currentMesocycleId;
    if (mesocycleId != null &&
        (await candidate
                .customSelect(
                  'SELECT 1 FROM mesocycles WHERE id = $mesocycleId LIMIT 1',
                )
                .get())
            .isEmpty) {
      throw const BackupRestoreException(
        'Invalid backup settings: currentMesocycleId does not exist in the '
        'backup database.',
      );
    }

    final completedWorkoutId = settings.currentCompletedWorkoutId;
    if (completedWorkoutId != null &&
        (await candidate
                .customSelect(
                  'SELECT 1 FROM completed_workouts '
                  'WHERE id = $completedWorkoutId LIMIT 1',
                )
                .get())
            .isEmpty) {
      throw const BackupRestoreException(
        'Invalid backup settings: currentCompletedWorkoutId does not exist in '
        'the backup database.',
      );
    }
  }

  String _quoteIdentifier(String identifier) =>
      '"${identifier.replaceAll('"', '""')}"';

  Future<void> _replaceLiveState(BackupSettings restoredSettings) async {
    final originalSettings = settingsStore.read();
    var databaseClosed = false;
    var originalSaved = false;
    var replacementAttempted = false;
    var settingsMayHaveChanged = false;

    try {
      if (!await fileOperations.exists(databasePath)) {
        throw const BackupRestoreException(
          'Restore failed: the current database file is missing.',
        );
      }

      await databaseLifecycle.checkpointAndClose();
      databaseClosed = true;

      await fileOperations.copy(databasePath, _rollbackPath);
      originalSaved = true;
      await _deleteSidecars();
      replacementAttempted = true;
      await fileOperations.rename(_stagedPath, databasePath);

      settingsMayHaveChanged = true;
      await settingsStore.write(restoredSettings);
    } catch (error) {
      final recoveryErrors = <Object>[];
      var databaseSafeToReopen = databaseClosed && !replacementAttempted;
      if (originalSaved && replacementAttempted) {
        try {
          await _deleteSidecars();
          await fileOperations.copy(_rollbackPath, databasePath);
          databaseSafeToReopen = true;
        } catch (recoveryError) {
          recoveryErrors.add(recoveryError);
        }
      }
      if (settingsMayHaveChanged) {
        try {
          await settingsStore.write(originalSettings);
        } catch (recoveryError) {
          recoveryErrors.add(recoveryError);
        }
      }
      if (databaseSafeToReopen) {
        try {
          await databaseLifecycle.reopenAfterFailure();
        } catch (recoveryError) {
          recoveryErrors.add(recoveryError);
        }
      }

      await _deleteBestEffort(_stagedPath);
      if (recoveryErrors.isEmpty) {
        await _deleteBestEffort(_rollbackPath);
        throw BackupRestoreException(
          'Restore failed during replacement; the original database and '
          'settings were recovered. ${_errorText(error)}',
        );
      }
      throw BackupRestoreException(
        'Restore failed and automatic recovery was incomplete. The preserved '
        'database is at $_rollbackPath. ${_errorText(error)}',
      );
    }

    await _deleteBestEffort(_rollbackPath);
  }

  Future<void> _deleteSidecars() async {
    await fileOperations.delete('$databasePath-wal');
    await fileOperations.delete('$databasePath-shm');
  }

  Future<void> _deleteBestEffort(String path) async {
    try {
      await fileOperations.delete(path);
    } catch (_) {
      // Cleanup cannot make an otherwise recovered or completed restore unsafe.
    }
  }

  String _errorText(Object error) =>
      error is BackupRestoreException ? error.message : error.toString();
}

class _BoundedBytesSink implements Sink<List<int>> {
  _BoundedBytesSink(this.limit);

  final int limit;
  final BytesBuilder _builder = BytesBuilder(copy: false);

  Uint8List get bytes => _builder.toBytes();

  @override
  void add(List<int> data) {
    if (_builder.length + data.length > limit) {
      throw const BackupRestoreException(
        'Invalid backup: an extracted file is too large.',
      );
    }
    _builder.add(data);
  }

  @override
  void close() {}
}

class _PreparedBackup {
  const _PreparedBackup(this.databaseBytes, this.settings);

  final List<int> databaseBytes;
  final BackupSettings settings;
}

class BackupService {
  static const zipFileName = 'workout_of_record.zip';
  static bool _restoreInProgress = false;

  /// Builds the backup zip and returns raw bytes without writing to disk.
  static Future<Uint8List> buildBackupBytes() async {
    // Flush WAL data into the main database file so the backup is complete.
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(
      p.join(docsDir.path, BackupRestoreService.databaseFileName),
    );
    if (!await dbFile.exists()) throw Exception('Database file not found');

    final dbBytes = await dbFile.readAsBytes();
    if (dbBytes.length > BackupRestoreService.maxDatabaseBytes) {
      throw const BackupRestoreException(
        'Backup failed: the database is too large for the supported format.',
      );
    }
    final settingsBytes = utf8.encode(
      jsonEncode(const AppPreferencesBackupSettingsStore().read().toJson()),
    );

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          BackupRestoreService.databaseFileName,
          dbBytes.length,
          dbBytes,
        ),
      )
      ..addFile(
        ArchiveFile(
          BackupRestoreService.settingsFileName,
          settingsBytes.length,
          settingsBytes,
        ),
      );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Failed to create ZIP');
    if (zipBytes.length > BackupRestoreService.maxArchiveBytes) {
      throw const BackupRestoreException(
        'Backup failed: the ZIP is too large for this app to restore.',
      );
    }
    return Uint8List.fromList(zipBytes);
  }

  /// Writes backup zip to the user-chosen SAF folder at [folderUri].
  static Future<void> backup(String folderUri) async {
    final zipBytes = await buildBackupBytes();
    await SafService.writeFile(folderUri, zipBytes);
    await AppPreferences.setLastBackupTimestamp(DateTime.now());
  }

  static Future<void> restore(String zipPath) async {
    if (_restoreInProgress) {
      throw const BackupRestoreException(
        'A backup restore is already in progress.',
      );
    }
    _restoreInProgress = true;
    try {
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw const BackupRestoreException(
          'The selected backup file is missing.',
        );
      }
      if (await zipFile.length() > BackupRestoreService.maxArchiveBytes) {
        throw const BackupRestoreException(
          'Invalid backup: the ZIP file is too large.',
        );
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final service = BackupRestoreService(
        databasePath: p.join(
          docsDir.path,
          BackupRestoreService.databaseFileName,
        ),
        settingsStore: const AppPreferencesBackupSettingsStore(),
        databaseLifecycle: const AppDatabaseRestoreLifecycle(),
      );
      await service.restoreBytes(await zipFile.readAsBytes());
    } finally {
      _restoreInProgress = false;
    }
  }
}
