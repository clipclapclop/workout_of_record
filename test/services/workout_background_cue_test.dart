import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/workout_background_cue.dart';
import 'package:workout_of_record/services/workout_cue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.clipclapclop.workoutofrecord/workout_cue_test',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('passes the complete cue request to the foreground engine', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    final delivered = await WorkoutBackgroundCue(
      channel: channel,
    ).fire(cueText: '12 reps', sound: TimerSound.tts, haptic: true);

    expect(delivered, isTrue);
    expect(received?.method, 'fire');
    expect(received?.arguments, {
      'cueText': '12 reps',
      'sound': 'tts',
      'haptic': true,
    });
  });

  test(
    'reports unavailable native delivery for task-isolate fallback',
    () async {
      final delivered = await WorkoutBackgroundCue(
        channel: channel,
      ).fire(cueText: null, sound: TimerSound.chime, haptic: false);

      expect(delivered, isFalse);
    },
  );

  test('explicit settings do not require UI-isolate preferences', () async {
    final delivered = await WorkoutCueService.fire(
      null,
      soundOverride: TimerSound.silent,
      hapticOverride: false,
    );

    expect(delivered, isTrue);
  });
}
