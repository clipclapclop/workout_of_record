import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/workout_foreground_service.dart';

void main() {
  final now = DateTime.utc(2026, 8, 9, 12);

  Map<String, dynamic> update({
    required DateTime endsAt,
    String sound = 'tts',
    bool haptic = true,
  }) => {
    'type': 'update',
    'exerciseName': 'Bench press',
    'cueText': '12 reps',
    'setInfo': 'Set 2/4',
    'sound': sound,
    'haptic': haptic,
    'timerEndsAtMs': endsAt.millisecondsSinceEpoch,
  };

  test('expires once with the cue settings sent by the UI isolate', () {
    final state = WorkoutTimerTaskState()
      ..receive(update(endsAt: now.add(const Duration(seconds: 5))));

    final counting = state.tick(now);
    expect(counting.shouldCue, isFalse);
    expect(counting.notificationTitle, 'Bench press');
    expect(counting.notificationText, 'Set 2/4  |  Rest: 00:05');

    final expired = state.tick(now.add(const Duration(seconds: 5)));
    expect(expired.shouldCue, isTrue);
    expect(expired.cueText, '12 reps');
    expect(expired.sound, TimerSound.tts);
    expect(expired.haptic, isTrue);
    expect(expired.notificationText, 'Set 2/4  |  Ready!');

    final repeated = state.tick(now.add(const Duration(seconds: 6)));
    expect(repeated.shouldCue, isFalse);
    expect(repeated.notificationText, 'Set 2/4  |  Ready!');
  });

  test('a UI fallback suppresses later foreground-task delivery', () {
    final state = WorkoutTimerTaskState()
      ..receive(update(endsAt: now))
      ..receive({'type': 'widgetCued'});

    final tick = state.tick(now.add(const Duration(seconds: 1)));

    expect(tick.shouldCue, isFalse);
    expect(tick.notificationText, 'Set 2/4  |  Ready!');
  });

  test('invalid persisted sound data safely falls back to speech', () {
    final state = WorkoutTimerTaskState()
      ..receive(update(endsAt: now, sound: 'unknown', haptic: false));

    final tick = state.tick(now);

    expect(tick.shouldCue, isTrue);
    expect(tick.sound, TimerSound.tts);
    expect(tick.haptic, isFalse);
  });
}
