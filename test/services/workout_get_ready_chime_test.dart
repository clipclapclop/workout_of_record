import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/services/workout_get_ready_chime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.clipclapclop.workoutofrecord/get_ready_chime',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('detects descending thresholds without chiming immediately', () {
    expect(getReadyChimeCrossed(11000, 10000), GetReadyChime.tenSeconds);
    expect(getReadyChimeCrossed(6000, 5000), GetReadyChime.fiveSeconds);
    expect(getReadyChimeCrossed(10000, 9000), isNull);
    expect(getReadyChimeCrossed(5000, 4000), isNull);
    expect(getReadyChimeCrossed(12000, 4000), GetReadyChime.fiveSeconds);
  });

  test('requests the low and high native chimes', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    expect(
      await WorkoutGetReadyChimeService.play(GetReadyChime.tenSeconds),
      isTrue,
    );
    expect(
      await WorkoutGetReadyChimeService.play(GetReadyChime.fiveSeconds),
      isTrue,
    );
    expect(calls, [
      isA<MethodCall>().having((call) => call.method, 'method', 'play').having(
        (call) => call.arguments,
        'arguments',
        {'chime': 'tenSeconds'},
      ),
      isA<MethodCall>().having((call) => call.method, 'method', 'play').having(
        (call) => call.arguments,
        'arguments',
        {'chime': 'fiveSeconds'},
      ),
    ]);
  });

  test('reports unavailable native playback', () async {
    expect(
      await WorkoutGetReadyChimeService.play(GetReadyChime.tenSeconds),
      isFalse,
    );
  });
}
