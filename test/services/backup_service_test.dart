import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/backup_service.dart';

class _DatabaseFixture {
  const _DatabaseFixture({
    required this.mesocycleId,
    required this.activeWorkoutId,
    required this.historicalWorkoutId,
  });

  final int mesocycleId;
  final int activeWorkoutId;
  final int historicalWorkoutId;
}

class _MemorySettingsStore implements BackupSettingsStore {
  _MemorySettingsStore(this.current);

  BackupSettings current;
  int writesToFailAfterMutation = 0;

  @override
  BackupSettings read() => current;

  @override
  Future<void> write(BackupSettings settings) async {
    current = settings;
    if (writesToFailAfterMutation > 0) {
      writesToFailAfterMutation--;
      throw StateError('injected settings write failure');
    }
  }
}

class _TestDatabaseLifecycle implements DatabaseRestoreLifecycle {
  _TestDatabaseLifecycle(this.path);

  final String path;
  AppDatabase? database;
  int closeCount = 0;
  int reopenCount = 0;

  Future<void> open() async {
    database = AppDatabase.withExecutor(NativeDatabase(File(path)));
    await database!.customSelect('SELECT 1').get();
  }

  Future<void> removeLiveDatabaseBeforeRestore() async {
    await dispose();
    await File(path).delete();
    database = AppDatabase.withExecutor(NativeDatabase(File(path)));
  }

  @override
  Map<String, List<String>> get expectedSchema => {
    for (final table in database!.allTables)
      table.entityName: [for (final column in table.$columns) column.$name],
  };

  @override
  Future<void> checkpointAndClose() async {
    await database!.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await database!.close();
    database = null;
    closeCount++;
  }

  @override
  Future<void> reopenAfterFailure() async {
    reopenCount++;
    await open();
  }

  Future<void> dispose() async {
    await database?.close();
    database = null;
  }
}

class _RecordingFileOperations extends LocalRestoreFileOperations {
  _RecordingFileOperations({
    this.failLiveRenameDestination,
    this.failRollbackCopyDestination,
    this.failRollbackRenameDestination,
  });

  final String? failLiveRenameDestination;
  final String? failRollbackCopyDestination;
  final String? failRollbackRenameDestination;
  final List<String> deletedPaths = [];
  bool _renameFailed = false;
  bool _rollbackCopyFailed = false;

  @override
  Future<void> copy(String source, String destination) async {
    if (!_rollbackCopyFailed &&
        source.endsWith('.restore-original') &&
        destination == failRollbackCopyDestination) {
      _rollbackCopyFailed = true;
      throw FileSystemException('injected rollback copy failure', destination);
    }
    await super.copy(source, destination);
  }

  @override
  Future<void> delete(String path) async {
    deletedPaths.add(path);
    await super.delete(path);
  }

  @override
  Future<void> rename(String source, String destination) async {
    if (source.endsWith('.restore-original') &&
        destination == failRollbackRenameDestination) {
      throw FileSystemException(
        'injected rollback rename failure',
        destination,
      );
    }
    if (!_renameFailed && destination == failLiveRenameDestination) {
      _renameFailed = true;
      throw FileSystemException('injected rename failure', destination);
    }
    await super.rename(source, destination);
  }
}

Future<_DatabaseFixture> _createRepresentativeDatabase(
  String path,
  String mesocycleName,
) async {
  final database = AppDatabase.withExecutor(NativeDatabase(File(path)));
  try {
    final templates = await database.getMesoTemplates();
    final mesocycleId = await database.createMesocycle(
      templates.first.id,
      mesocycleName,
      2,
    );
    final historicalWorkout = await database.getOrCreateNextWorkout(
      mesocycleId,
    );
    await database.generatePlannedWorkout(historicalWorkout!.id);
    final historicalWorkoutId = await database.initializeWorkout(
      historicalWorkout.id,
    );
    await database.finishWorkout(historicalWorkoutId);

    final activeWorkout = await database.getOrCreateNextWorkout(mesocycleId);
    await database.generatePlannedWorkout(activeWorkout!.id);
    final activeWorkoutId = await database.initializeWorkout(activeWorkout.id);
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    return _DatabaseFixture(
      mesocycleId: mesocycleId,
      activeWorkoutId: activeWorkoutId,
      historicalWorkoutId: historicalWorkoutId,
    );
  } finally {
    await database.close();
  }
}

List<int> _archiveBytes(List<ArchiveFile> files) {
  final archive = Archive();
  for (final file in files) {
    archive.addFile(file);
  }
  return ZipEncoder().encode(archive)!;
}

ArchiveFile _databaseEntry(List<int> bytes) =>
    ArchiveFile(BackupRestoreService.databaseFileName, bytes.length, bytes);

ArchiveFile _settingsEntry(Object json) {
  final bytes = utf8.encode(jsonEncode(json));
  return ArchiveFile(
    BackupRestoreService.settingsFileName,
    bytes.length,
    bytes,
  );
}

List<int> _validArchive(List<int> databaseBytes, BackupSettings settings) =>
    _archiveBytes([
      _databaseEntry(databaseBytes),
      _settingsEntry(settings.toJson()),
    ]);

List<int> _archiveWithDuplicateDatabaseEntry(
  List<int> databaseBytes,
  BackupSettings settings,
) {
  final requiredName = BackupRestoreService.databaseFileName;
  final placeholder = List.filled(requiredName.length, 'x').join();
  final bytes = _archiveBytes([
    _databaseEntry(databaseBytes),
    _settingsEntry(settings.toJson()),
    ArchiveFile(placeholder, databaseBytes.length, databaseBytes),
  ]);
  final placeholderBytes = utf8.encode(placeholder);
  final requiredNameBytes = utf8.encode(requiredName);
  for (
    var offset = 0;
    offset <= bytes.length - placeholderBytes.length;
    offset++
  ) {
    var matches = true;
    for (var index = 0; index < placeholderBytes.length; index++) {
      if (bytes[offset + index] != placeholderBytes[index]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      bytes.setRange(
        offset,
        offset + requiredNameBytes.length,
        requiredNameBytes,
      );
      offset += requiredNameBytes.length - 1;
    }
  }
  return bytes;
}

List<int> _forgeDeclaredDatabaseSize(List<int> archive, int declaredSize) {
  final bytes = Uint8List.fromList(archive);
  final data = ByteData.sublistView(bytes);
  final requiredName = BackupRestoreService.databaseFileName;
  var patchedHeaders = 0;

  for (var offset = 0; offset <= bytes.length - 30; offset++) {
    final signature = data.getUint32(offset, Endian.little);
    int? nameOffset;
    int? nameLength;
    int? sizeOffset;
    if (signature == 0x04034b50) {
      nameLength = data.getUint16(offset + 26, Endian.little);
      nameOffset = offset + 30;
      sizeOffset = offset + 22;
    } else if (signature == 0x02014b50 && offset <= bytes.length - 46) {
      nameLength = data.getUint16(offset + 28, Endian.little);
      nameOffset = offset + 46;
      sizeOffset = offset + 24;
    }
    if (nameOffset == null || nameOffset + nameLength! > bytes.length) {
      continue;
    }
    if (utf8.decode(bytes.sublist(nameOffset, nameOffset + nameLength)) ==
        requiredName) {
      data.setUint32(sizeOffset!, declaredSize, Endian.little);
      patchedHeaders++;
    }
  }

  if (patchedHeaders != 2) {
    throw StateError('Expected to patch local and central database headers.');
  }
  return bytes;
}

Future<List<String>> _mesocycleNames(String path) async {
  final database = AppDatabase.withExecutor(
    NativeDatabase(File(path), enableMigrations: false),
  );
  try {
    return [
      for (final row in await database.select(database.mesocycles).get())
        row.name,
    ];
  } finally {
    await database.close();
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  late Directory tempDirectory;
  late String livePath;
  late String restoredPath;
  late _DatabaseFixture restoredFixture;
  late List<int> restoredDatabaseBytes;
  late BackupSettings originalSettings;
  late BackupSettings restoredSettings;
  late _MemorySettingsStore settingsStore;
  late _TestDatabaseLifecycle lifecycle;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'backup_restore_test_',
    );
    livePath = '${tempDirectory.path}/live.sqlite';
    restoredPath = '${tempDirectory.path}/restored.sqlite';

    await _createRepresentativeDatabase(livePath, 'Original history');
    restoredFixture = await _createRepresentativeDatabase(
      restoredPath,
      'Restored history',
    );
    restoredDatabaseBytes = await File(restoredPath).readAsBytes();

    originalSettings = const BackupSettings(
      dateOfBirth: null,
      weight: 80,
      trainingGoal: TrainingGoal.strength,
      calorieState: CalorieState.maintenance,
      aiEnabled: false,
      hasSeenProfilePrompt: false,
      notes: 'Original synthetic note',
    );
    restoredSettings = BackupSettings(
      currentMesocycleId: restoredFixture.mesocycleId,
      currentCompletedWorkoutId: restoredFixture.activeWorkoutId,
      dateOfBirth: DateTime.utc(1990, 2, 3),
      weight: 72.5,
      trainingGoal: TrainingGoal.hypertrophy,
      calorieState: CalorieState.surplus,
      trainingStartDate: DateTime.utc(2020, 4, 5),
      timerEnabled: false,
      timerDefaultSeconds: 90,
      timerSound: TimerSound.chime,
      timerHaptic: false,
      timerKeepAwake: true,
      timerGetReadyChimes: true,
      aiEnabled: true,
      aiModel: 'synthetic-model',
      aiCreditId: 'synthetic-credit-id',
      aiRecommendationPrompt: 'Synthetic recommendation prompt',
      aiChatPrompt: 'Synthetic chat prompt',
      aiHistoryWeeks: 8,
      aiUserNotes: 'Synthetic AI notes',
      hasSeenProfilePrompt: true,
      notes: 'Restored synthetic note',
    );
    settingsStore = _MemorySettingsStore(originalSettings);
    lifecycle = _TestDatabaseLifecycle(livePath);
    await lifecycle.open();
  });

  tearDown(() async {
    await lifecycle.dispose();
    await tempDirectory.delete(recursive: true);
  });

  BackupRestoreService service({
    RestoreFileOperations? files,
    int databaseSizeLimit = BackupRestoreService.maxDatabaseBytes,
  }) => BackupRestoreService(
    databasePath: livePath,
    settingsStore: settingsStore,
    databaseLifecycle: lifecycle,
    fileOperations: files ?? const LocalRestoreFileOperations(),
    databaseSizeLimit: databaseSizeLimit,
  );

  Future<void> expectRejectedWithoutMutation(
    List<int> archive,
    String messageFragment,
  ) async {
    await expectLater(
      service().restoreBytes(archive),
      throwsA(
        isA<BackupRestoreException>().having(
          (error) => error.message,
          'message',
          contains(messageFragment),
        ),
      ),
    );
    expect(lifecycle.closeCount, 0);
    expect(settingsStore.current, originalSettings);
    expect(await _mesocycleNames(livePath), contains('Original history'));
  }

  group('archive validation', () {
    test(
      'rejects malformed ZIP data before closing the live database',
      () async {
        await File('$livePath.restore-original').writeAsBytes([1, 2, 3]);

        await expectRejectedWithoutMutation(
          utf8.encode('not a zip'),
          'malformed or corrupt',
        );
        expect(await File('$livePath.restore-original').exists(), true);
      },
    );

    test('rejects a missing required entry', () async {
      await expectRejectedWithoutMutation(
        _archiveBytes([_databaseEntry(restoredDatabaseBytes)]),
        'required database or settings file is missing',
      );
    });

    test('rejects duplicate required entries', () async {
      await expectRejectedWithoutMutation(
        _archiveWithDuplicateDatabaseEntry(
          restoredDatabaseBytes,
          restoredSettings,
        ),
        'must not be duplicated',
      );
    });

    test('rejects forged sizes without unbounded decompression', () async {
      final archive = _forgeDeclaredDatabaseSize(
        _validArchive(restoredDatabaseBytes, restoredSettings),
        512,
      );

      await expectLater(
        service(databaseSizeLimit: 1024).restoreBytes(archive),
        throwsA(
          isA<BackupRestoreException>().having(
            (error) => error.message,
            'message',
            contains('extracted file is too large'),
          ),
        ),
      );
      expect(lifecycle.closeCount, 0);
      expect(settingsStore.current, originalSettings);
    });

    test('rejects unexpected and nested entries', () async {
      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(restoredDatabaseBytes),
          _settingsEntry(restoredSettings.toJson()),
          ArchiveFile('nested/extra.txt', 1, [1]),
        ]),
        'only the two required root-level files',
      );
    });
  });

  group('settings validation', () {
    test(
      'production settings adapter round-trips every backed-up value',
      () async {
        SharedPreferences.setMockInitialValues({
          'backup_enabled': true,
          'auto_backup_enabled': true,
          'backup_directory_path': 'synthetic-backup-folder',
          'ai_logging_enabled': true,
          'ai_log_directory_path': 'synthetic-log-folder',
        });
        await AppPreferences.init();
        const store = AppPreferencesBackupSettingsStore();

        await store.write(restoredSettings);

        expect(store.read(), restoredSettings);
        expect(AppPreferences.getBackupEnabled(), isTrue);
        expect(AppPreferences.getAutoBackupEnabled(), isTrue);
        expect(
          AppPreferences.getBackupDirectoryPath(),
          'synthetic-backup-folder',
        );
        expect(AppPreferences.getAiLoggingEnabled(), isTrue);
        expect(AppPreferences.getAiLogDirectoryPath(), 'synthetic-log-folder');
      },
    );

    for (final legacyMetricValue in [false, true]) {
      test(
        'restores legacy unitsMetric=$legacyMetricValue without conversion',
        () async {
          final legacySettings = {
            ...restoredSettings.toJson(),
            'unitsMetric': legacyMetricValue,
          };

          await service().restoreBytes(
            _archiveBytes([
              _databaseEntry(restoredDatabaseBytes),
              _settingsEntry(legacySettings),
            ]),
          );

          expect(settingsStore.current, restoredSettings);
          expect(settingsStore.current.weight, 72.5);
          expect(
            settingsStore.current.toJson(),
            isNot(contains('unitsMetric')),
          );
        },
      );
    }

    test('rejects malformed JSON', () async {
      final malformed = utf8.encode('{');
      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(restoredDatabaseBytes),
          ArchiveFile(
            BackupRestoreService.settingsFileName,
            malformed.length,
            malformed,
          ),
        ]),
        'JSON is malformed',
      );
    });

    final invalidSettings = <String, Map<String, Object?>>{
      'wrong pointer type': {'currentMesocycleId': '1'},
      'unknown profile enum': {'trainingGoal': 'powerlifting'},
      'wrong legacy boolean type': {'unitsMetric': 1},
      'invalid profile date': {'dateOfBirth': 'not-a-date'},
      'invalid training date': {'trainingStartDate': 'not-a-date'},
      'zero weight': {'weight': 0},
      'negative weight': {'weight': -1},
      'wrong timer boolean type': {'timerEnabled': 1},
      'non-positive timer duration': {'timerDefaultSeconds': 0},
      'unknown timer sound': {'timerSound': 'airHorn'},
      'null timer sound': {'timerSound': null},
      'wrong AI model type': {'aiModel': 4},
      'wrong AI credit ID type': {'aiCreditId': true},
      'wrong AI prompt type': {'aiRecommendationPrompt': 4},
      'AI history below range': {'aiHistoryWeeks': 0},
      'AI history above range': {'aiHistoryWeeks': 13},
      'wrong AI notes type': {'aiUserNotes': false},
      'unknown field': {'futureSetting': true},
    };

    for (final entry in invalidSettings.entries) {
      test('rejects ${entry.key}', () async {
        await expectRejectedWithoutMutation(
          _archiveBytes([
            _databaseEntry(restoredDatabaseBytes),
            _settingsEntry(entry.value),
          ]),
          'Invalid backup settings',
        );
      });
    }

    test('rejects a pointer absent from the staged database', () async {
      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(restoredDatabaseBytes),
          _settingsEntry({'currentMesocycleId': 999999}),
        ]),
        'currentMesocycleId does not identify an active mesocycle',
      );
    });

    test(
      'rejects active workout and mesocycle pointers that do not match',
      () async {
        final mismatchedPath = '${tempDirectory.path}/mismatched.sqlite';
        await File(restoredPath).copy(mismatchedPath);
        final mismatchedDatabase = AppDatabase.withExecutor(
          NativeDatabase(File(mismatchedPath), enableMigrations: false),
        );
        final templates = await mismatchedDatabase.getMesoTemplates();
        final otherMesocycleId = await mismatchedDatabase.createMesocycle(
          templates.first.id,
          'Different active mesocycle',
          2,
        );
        await mismatchedDatabase.close();

        await expectRejectedWithoutMutation(
          _archiveBytes([
            _databaseEntry(await File(mismatchedPath).readAsBytes()),
            _settingsEntry({
              ...restoredSettings.toJson(),
              'currentMesocycleId': otherMesocycleId,
            }),
          ]),
          'active workout in the current mesocycle',
        );
      },
    );
  });

  group('SQLite validation', () {
    test('rejects a non-SQLite required entry', () async {
      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(utf8.encode('not sqlite')),
          _settingsEntry({}),
        ]),
        'SQLite file is malformed or incompatible',
      );
    });

    test('rejects a newer schema version', () async {
      final incompatiblePath = '${tempDirectory.path}/newer.sqlite';
      await File(restoredPath).copy(incompatiblePath);
      final database = AppDatabase.withExecutor(
        NativeDatabase(File(incompatiblePath), enableMigrations: false),
      );
      await database.customStatement(
        'PRAGMA user_version = ${currentDatabaseSchemaVersion + 1}',
      );
      await database.close();

      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(await File(incompatiblePath).readAsBytes()),
          _settingsEntry({}),
        ]),
        'Incompatible backup database schema',
      );
    });

    test(
      'rejects a schema older than the maintained migration range',
      () async {
        final incompatiblePath = '${tempDirectory.path}/older.sqlite';
        await File(restoredPath).copy(incompatiblePath);
        final database = AppDatabase.withExecutor(
          NativeDatabase(File(incompatiblePath), enableMigrations: false),
        );
        await database.customStatement(
          'PRAGMA user_version = ${minimumRestorableSchemaVersion - 1}',
        );
        await database.close();

        await expectRejectedWithoutMutation(
          _archiveBytes([
            _databaseEntry(await File(incompatiblePath).readAsBytes()),
            _settingsEntry({}),
          ]),
          'Incompatible backup database schema',
        );
      },
    );

    test(
      'rejects a database claiming the current version without the schema',
      () async {
        final emptyPath = '${tempDirectory.path}/empty.sqlite';
        final database = AppDatabase.withExecutor(
          NativeDatabase(File(emptyPath), enableMigrations: false),
        );
        await database.customStatement(
          'PRAGMA user_version = $currentDatabaseSchemaVersion',
        );
        await database.close();

        await expectRejectedWithoutMutation(
          _archiveBytes([
            _databaseEntry(await File(emptyPath).readAsBytes()),
            _settingsEntry({}),
          ]),
          'SQLite file is malformed or incompatible',
        );
      },
    );

    test('rejects unusable persisted numeric values', () async {
      final invalidPath = '${tempDirectory.path}/invalid-numbers.sqlite';
      await File(restoredPath).copy(invalidPath);
      final database = AppDatabase.withExecutor(
        NativeDatabase(File(invalidPath), enableMigrations: false),
      );
      await database.customStatement('UPDATE completed_sets SET reps = 0');
      await database.close();

      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(await File(invalidPath).readAsBytes()),
          _settingsEntry({}),
        ]),
        'stored numeric values are unusable',
      );
    });

    test('rejects foreign-key violations', () async {
      final inconsistentPath = '${tempDirectory.path}/inconsistent.sqlite';
      await File(restoredPath).copy(inconsistentPath);
      final database = AppDatabase.withExecutor(
        NativeDatabase(File(inconsistentPath), enableMigrations: false),
      );
      await database.customStatement('PRAGMA foreign_keys = OFF');
      await database.customStatement('''
        INSERT INTO weeks
          (mesocycle_id, week_number, goal, created_at)
        VALUES (999999, 99, 'hard', 0)
      ''');
      await database.close();

      await expectRejectedWithoutMutation(
        _archiveBytes([
          _databaseEntry(await File(inconsistentPath).readAsBytes()),
          _settingsEntry({}),
        ]),
        'related workout records are inconsistent',
      );
    });
  });

  group('recoverable replacement', () {
    test(
      'restores the original state when database replacement fails',
      () async {
        final files = _RecordingFileOperations(
          failLiveRenameDestination: livePath,
        );

        await expectLater(
          service(files: files).restoreBytes(
            _validArchive(restoredDatabaseBytes, restoredSettings),
          ),
          throwsA(
            isA<BackupRestoreException>().having(
              (error) => error.message,
              'message',
              contains('original database and settings were recovered'),
            ),
          ),
        );

        expect(lifecycle.closeCount, 1);
        expect(lifecycle.reopenCount, 1);
        expect(settingsStore.current, originalSettings);
        expect(await _mesocycleNames(livePath), contains('Original history'));
        expect(await File('$livePath.restore-original').exists(), false);
      },
    );

    test(
      'restores database and settings when settings application fails',
      () async {
        settingsStore.writesToFailAfterMutation = 1;

        await expectLater(
          service().restoreBytes(
            _validArchive(restoredDatabaseBytes, restoredSettings),
          ),
          throwsA(isA<BackupRestoreException>()),
        );

        expect(lifecycle.reopenCount, 1);
        expect(settingsStore.current, originalSettings);
        expect(await _mesocycleNames(livePath), contains('Original history'));
        expect(
          await _mesocycleNames(livePath),
          isNot(contains('Restored history')),
        );
      },
    );

    test(
      'reopens the recovered database when settings recovery is incomplete',
      () async {
        // Fail the candidate write and both attempts to restore the snapshot.
        settingsStore.writesToFailAfterMutation = 3;

        await expectLater(
          service().restoreBytes(
            _validArchive(restoredDatabaseBytes, restoredSettings),
          ),
          throwsA(
            isA<BackupRestoreException>().having(
              (error) => error.message,
              'message',
              contains('automatic recovery was incomplete'),
            ),
          ),
        );

        expect(lifecycle.reopenCount, 1);
        expect(await _mesocycleNames(livePath), contains('Original history'));
        expect(await File('$livePath.restore-original').exists(), true);
      },
    );

    test(
      'falls back to renaming the original when rollback copy fails',
      () async {
        settingsStore.writesToFailAfterMutation = 1;
        final files = _RecordingFileOperations(
          failRollbackCopyDestination: livePath,
        );

        await expectLater(
          service(files: files).restoreBytes(
            _validArchive(restoredDatabaseBytes, restoredSettings),
          ),
          throwsA(
            isA<BackupRestoreException>().having(
              (error) => error.message,
              'message',
              contains('original database and settings were recovered'),
            ),
          ),
        );

        expect(lifecycle.reopenCount, 1);
        expect(settingsStore.current, originalSettings);
        expect(await _mesocycleNames(livePath), contains('Original history'));
        expect(await File('$livePath.restore-original').exists(), false);
      },
    );

    test('fails closed when both rollback methods fail', () async {
      settingsStore.writesToFailAfterMutation = 1;
      final files = _RecordingFileOperations(
        failRollbackCopyDestination: livePath,
        failRollbackRenameDestination: livePath,
      );

      await expectLater(
        service(
          files: files,
        ).restoreBytes(_validArchive(restoredDatabaseBytes, restoredSettings)),
        throwsA(
          isA<BackupRestoreException>().having(
            (error) => error.message,
            'message',
            contains('automatic recovery was incomplete'),
          ),
        ),
      );

      expect(lifecycle.reopenCount, 0);
      expect(settingsStore.current, originalSettings);
      expect(await File('$livePath.restore-original').exists(), true);
    });
  });

  test(
    'startup rolls back a restore interrupted between both stores',
    () async {
      await lifecycle.dispose();
      final originalDatabaseBytes = await File(livePath).readAsBytes();
      await File(
        '$livePath.restore-original',
      ).writeAsBytes(originalDatabaseBytes, flush: true);
      await File(restoredPath).copy(livePath);
      settingsStore.current = restoredSettings;
      await File('$livePath.restore-transaction.json').writeAsString(
        jsonEncode({
          'version': 1,
          'hadLiveDatabase': true,
          'originalSettings': originalSettings.toJson(),
        }),
        flush: true,
      );

      await BackupRestoreService.recoverInterruptedRestore(
        databasePath: livePath,
        settingsStore: settingsStore,
      );

      expect(settingsStore.current, originalSettings);
      expect(await _mesocycleNames(livePath), contains('Original history'));
      expect(
        await _mesocycleNames(livePath),
        isNot(contains('Restored history')),
      );
      expect(await File('$livePath.restore-original').exists(), false);
      expect(await File('$livePath.restore-transaction.json').exists(), false);
    },
  );

  test('successful restore works when no live database file exists', () async {
    await lifecycle.removeLiveDatabaseBeforeRestore();

    await service().restoreBytes(
      _validArchive(restoredDatabaseBytes, restoredSettings),
    );

    expect(settingsStore.current, restoredSettings);
    expect(await _mesocycleNames(livePath), contains('Restored history'));
    expect(await File('$livePath.restore-original').exists(), false);
  });

  test(
    'successful restore recovers settings, pointers, and workout history',
    () async {
      final files = _RecordingFileOperations();
      await lifecycle.database!.customStatement('PRAGMA journal_mode = WAL');
      await File('$livePath.restore-stage-wal').writeAsBytes([1, 2, 3]);
      await File('$livePath.restore-stage-shm').writeAsBytes([4, 5, 6]);
      await File('$livePath.restore-original').writeAsBytes([7, 8, 9]);

      await service(
        files: files,
      ).restoreBytes(_validArchive(restoredDatabaseBytes, restoredSettings));

      expect(settingsStore.current, restoredSettings);
      expect(lifecycle.closeCount, 1);
      expect(lifecycle.reopenCount, 0);
      expect(await _mesocycleNames(livePath), contains('Restored history'));
      expect(
        await _mesocycleNames(livePath),
        isNot(contains('Original history')),
      );

      final restoredDatabase = AppDatabase.withExecutor(
        NativeDatabase(File(livePath)),
      );
      try {
        final active =
            await (restoredDatabase.select(restoredDatabase.completedWorkouts)
                  ..where(
                    (row) => row.id.equals(restoredFixture.activeWorkoutId),
                  ))
                .getSingleOrNull();
        expect(active?.status, WorkoutStatus.active);
        expect(active?.completedAt, isNull);

        final historical =
            await (restoredDatabase.select(restoredDatabase.completedWorkouts)
                  ..where(
                    (row) => row.id.equals(restoredFixture.historicalWorkoutId),
                  ))
                .getSingleOrNull();
        expect(historical?.status, WorkoutStatus.completed);
        expect(historical?.completedAt, isNotNull);
      } finally {
        await restoredDatabase.close();
      }

      expect(files.deletedPaths, contains('$livePath-wal'));
      expect(files.deletedPaths, contains('$livePath-shm'));
      expect(files.deletedPaths, contains('$livePath.restore-stage-wal'));
      expect(files.deletedPaths, contains('$livePath.restore-stage-shm'));
      expect(await File('$livePath-wal').exists(), false);
      expect(await File('$livePath-shm').exists(), false);
      expect(await File('$livePath.restore-stage-wal').exists(), false);
      expect(await File('$livePath.restore-stage-shm').exists(), false);
      expect(await File('$livePath.restore-original').exists(), false);
    },
  );

  test(
    'legacy archives with omitted optional settings restore defaults',
    () async {
      await service().restoreBytes(
        _archiveBytes([
          _databaseEntry(restoredDatabaseBytes),
          _settingsEntry({}),
        ]),
      );

      expect(settingsStore.current, const BackupSettings());
      expect(await _mesocycleNames(livePath), contains('Restored history'));
    },
  );
}
