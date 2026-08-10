import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/services/workout_foreground_service.dart';
import 'package:workout_of_record/services/workout_get_ready_chime.dart';

void main() {
  final now = DateTime.utc(2026, 8, 9, 12);

  Map<String, dynamic> update({
    required DateTime endsAt,
    String sound = 'tts',
    bool haptic = true,
    bool getReadyChimes = false,
    int? remainingMsAtUpdate,
  }) => {
    'type': 'update',
    'exerciseName': 'Bench press',
    'cueText': '12 reps',
    'setInfo': 'Set 2/4',
    'sound': sound,
    'haptic': haptic,
    'getReadyChimes': getReadyChimes,
    'timerEndsAtMs': endsAt.millisecondsSinceEpoch,
    'timerRemainingMsAtUpdate':
        remainingMsAtUpdate ?? endsAt.difference(now).inMilliseconds,
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

  test('plays distinct get-ready chimes once as thresholds are crossed', () {
    final state = WorkoutTimerTaskState()
      ..receive(
        update(
          endsAt: now.add(const Duration(seconds: 12)),
          getReadyChimes: true,
        ),
      );

    expect(state.tick(now).getReadyChime, isNull);
    expect(
      state.tick(now.add(const Duration(seconds: 2))).getReadyChime,
      GetReadyChime.tenSeconds,
    );
    expect(
      state.tick(now.add(const Duration(seconds: 3))).getReadyChime,
      isNull,
    );
    expect(
      state.tick(now.add(const Duration(seconds: 7))).getReadyChime,
      GetReadyChime.fiveSeconds,
    );
    expect(
      state.tick(now.add(const Duration(seconds: 8))).getReadyChime,
      isNull,
    );
  });

  test('a timer started below ten seconds only chimes at five', () {
    final state = WorkoutTimerTaskState()
      ..receive(
        update(
          endsAt: now.add(const Duration(seconds: 8)),
          getReadyChimes: true,
          remainingMsAtUpdate: 8000,
        ),
      );

    expect(state.tick(now).getReadyChime, isNull);
    expect(
      state.tick(now.add(const Duration(seconds: 3))).getReadyChime,
      GetReadyChime.fiveSeconds,
    );
  });

  test('silent mode suppresses get-ready chimes', () {
    final state = WorkoutTimerTaskState()
      ..receive(
        update(
          endsAt: now.add(const Duration(seconds: 12)),
          sound: 'silent',
          getReadyChimes: true,
        ),
      );

    expect(state.tick(now).getReadyChime, isNull);
    expect(
      state.tick(now.add(const Duration(seconds: 2))).getReadyChime,
      isNull,
    );
  });

  test('resuming below a crossed threshold does not replay its chime', () {
    final state = WorkoutTimerTaskState()
      ..receive(
        update(
          endsAt: now.add(const Duration(seconds: 12)),
          getReadyChimes: true,
        ),
      );

    state.tick(now);
    expect(
      state.tick(now.add(const Duration(seconds: 2))).getReadyChime,
      GetReadyChime.tenSeconds,
    );

    state
      ..receive({'type': 'clearTimer'})
      ..receive(
        update(
          endsAt: now.add(const Duration(seconds: 9)),
          getReadyChimes: true,
          remainingMsAtUpdate: 7000,
        ),
      );

    expect(
      state.tick(now.add(const Duration(seconds: 2))).getReadyChime,
      isNull,
    );
    expect(
      state.tick(now.add(const Duration(seconds: 4))).getReadyChime,
      GetReadyChime.fiveSeconds,
    );
  });

  test('cue setting changes apply without resetting the deadline', () {
    final state = WorkoutTimerTaskState()
      ..receive(update(endsAt: now.add(const Duration(seconds: 5))))
      ..receive({'type': 'cueSettings', 'sound': 'chime', 'haptic': false});

    final tick = state.tick(now.add(const Duration(seconds: 5)));

    expect(tick.shouldCue, isTrue);
    expect(tick.sound, TimerSound.chime);
    expect(tick.haptic, isFalse);
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
