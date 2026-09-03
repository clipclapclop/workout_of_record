import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/services/rest_timer_recovery.dart';
import 'package:workout_of_record/widgets/rest_timer_controller.dart';

void main() {
  test('reopening restores a live timer with its original deadline', () {
    final controller = RestTimerController(durationSeconds: 0);
    addTearDown(controller.dispose);
    final now = DateTime.now();
    final endsAt = now.add(const Duration(seconds: 30));

    final restored = restorePersistedRestTimer(
      controller: controller,
      saved: ActiveRestTimerState(
        workoutId: 42,
        durationSeconds: 60,
        remainingMs: 30000,
        endsAt: endsAt,
      ),
      workoutId: 42,
      now: now,
    );

    expect(restored, isTrue);
    expect(controller.isRunning, isTrue);
    expect(controller.durationSeconds, 60);
    expect(controller.remainingMs, greaterThan(29000));
    expect(controller.remainingMs, lessThanOrEqualTo(30000));
  });

  test('reopening restores a paused timer without starting it', () {
    final controller = RestTimerController(durationSeconds: 0);
    addTearDown(controller.dispose);

    final restored = restorePersistedRestTimer(
      controller: controller,
      saved: const ActiveRestTimerState(
        workoutId: 42,
        durationSeconds: 60,
        remainingMs: 25000,
        endsAt: null,
      ),
      workoutId: 42,
    );

    expect(restored, isTrue);
    expect(controller.isRunning, isFalse);
    expect(controller.durationSeconds, 60);
    expect(controller.remainingMs, 25000);
  });

  test('expired or unrelated timers leave the controller idle', () {
    final controller = RestTimerController(durationSeconds: 15);
    addTearDown(controller.dispose);
    final now = DateTime.now();

    expect(
      restorePersistedRestTimer(
        controller: controller,
        saved: ActiveRestTimerState(
          workoutId: 41,
          durationSeconds: 60,
          remainingMs: 30000,
          endsAt: now.add(const Duration(seconds: 30)),
        ),
        workoutId: 42,
        now: now,
      ),
      isFalse,
    );
    expect(
      restorePersistedRestTimer(
        controller: controller,
        saved: ActiveRestTimerState(
          workoutId: 42,
          durationSeconds: 60,
          remainingMs: 0,
          endsAt: now.subtract(const Duration(seconds: 1)),
        ),
        workoutId: 42,
        now: now,
      ),
      isFalse,
    );
    expect(controller.isRunning, isFalse);
    expect(controller.durationSeconds, 15);
  });
}
