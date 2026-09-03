import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/widgets/rest_timer_controller.dart';

void main() {
  test('cue completion stops the countdown at zero', () {
    final controller = RestTimerController(durationSeconds: 60);
    addTearDown(controller.dispose);

    expect(controller.isRunning, isFalse);
    expect(controller.remainingMs, 60000);

    controller.setDuration(90);
    expect(controller.isRunning, isFalse);
    expect(controller.remainingMs, 90000);

    controller.start();
    expect(controller.isRunning, isTrue);

    controller.markCued();
    expect(controller.isRunning, isFalse);
    expect(controller.remainingMs, 0);

    controller.reset();
    expect(controller.isRunning, isFalse);
    expect(controller.remainingMs, 90000);
  });

  test('restores a running timer without moving its deadline', () {
    final controller = RestTimerController(durationSeconds: 0);
    addTearDown(controller.dispose);
    final endsAt = DateTime.now().add(const Duration(seconds: 30));

    controller.restoreRunningTimer(durationSeconds: 60, endsAt: endsAt);

    expect(controller.durationSeconds, 60);
    expect(controller.isRunning, isTrue);
    expect(controller.remainingMs, greaterThan(29000));
    expect(controller.remainingMs, lessThanOrEqualTo(30000));
  });

  test('final usable set ignores excluded sets in workout order', () {
    const orderedSetIds = [1, 2, 3, 4, 5];

    expect(
      isFinalUsableWorkoutSet(
        interactedSetId: 2,
        orderedSetIds: orderedSetIds,
        excludedSetIds: const {3, 4, 5},
      ),
      isTrue,
    );
    expect(
      isFinalUsableWorkoutSet(
        interactedSetId: 1,
        orderedSetIds: orderedSetIds,
        excludedSetIds: const {3, 4, 5},
      ),
      isFalse,
    );
    expect(
      isFinalUsableWorkoutSet(interactedSetId: 5, orderedSetIds: orderedSetIds),
      isTrue,
    );
  });
}
