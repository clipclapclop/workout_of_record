import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/services/backup_service.dart';

void main() {
  test('records success only after the platform write completes', () async {
    final writeStarted = Completer<void>();
    final releaseWrite = Completer<void>();
    final timestamps = <DateTime>[];
    final expectedTime = DateTime.utc(2026, 9, 3, 18, 30);
    final coordinator = BackupWriteCoordinator(
      buildBytes: () async => Uint8List.fromList([1, 2, 3]),
      writeFile: (_, _) async {
        writeStarted.complete();
        await releaseWrite.future;
      },
      markSuccessful: (timestamp) async => timestamps.add(timestamp),
      now: () => expectedTime,
    );

    final backup = coordinator.backup('synthetic-folder');
    await writeStarted.future;
    expect(timestamps, isEmpty);

    releaseWrite.complete();
    await backup;
    expect(timestamps, [expectedTime]);
  });

  test('does not record success when the platform write fails', () async {
    final timestamps = <DateTime>[];
    final coordinator = BackupWriteCoordinator(
      buildBytes: () async => Uint8List.fromList([1]),
      writeFile: (_, _) async => throw StateError('injected write failure'),
      markSuccessful: (timestamp) async => timestamps.add(timestamp),
    );

    await expectLater(coordinator.backup('synthetic-folder'), throwsStateError);
    expect(timestamps, isEmpty);
  });

  test(
    'serializes overlapping backup requests and continues after failure',
    () async {
      final firstWriteStarted = Completer<void>();
      final releaseFirstWrite = Completer<void>();
      final events = <String>[];
      var buildCount = 0;
      final coordinator = BackupWriteCoordinator(
        buildBytes: () async {
          buildCount++;
          events.add('build-$buildCount');
          return Uint8List.fromList([buildCount]);
        },
        writeFile: (folder, _) async {
          events.add('write-$folder');
          if (folder == 'first') {
            firstWriteStarted.complete();
            await releaseFirstWrite.future;
            throw StateError('injected first failure');
          }
        },
        markSuccessful: (_) async => events.add('success'),
      );

      final first = coordinator.backup('first');
      final second = coordinator.backup('second');
      await firstWriteStarted.future;
      expect(events, ['build-1', 'write-first']);

      releaseFirstWrite.complete();
      await expectLater(first, throwsStateError);
      await second;

      expect(events, [
        'build-1',
        'write-first',
        'build-2',
        'write-second',
        'success',
      ]);
    },
  );
}
