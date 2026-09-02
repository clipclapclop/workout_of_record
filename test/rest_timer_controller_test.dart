import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/widgets/rest_timer_controller.dart';

void main() {
  test('tracks whether a set has started the current timer', () {
    final controller = RestTimerController(durationSeconds: 60);
    addTearDown(controller.dispose);

    expect(controller.isRunning, isFalse);
    expect(controller.hasBeenStarted, isFalse);

    controller.setDuration(90);
    expect(controller.hasBeenStarted, isFalse);
    expect(controller.remainingMs, 90000);

    controller.start();
    expect(controller.isRunning, isTrue);
    expect(controller.hasBeenStarted, isTrue);

    controller.stop();
    expect(controller.isRunning, isFalse);
    expect(controller.hasBeenStarted, isTrue);
    controller.start();

    controller.markCued();
    expect(controller.isRunning, isFalse);
    expect(controller.hasBeenStarted, isTrue);
    expect(controller.remainingMs, 0);

    controller.reset();
    expect(controller.hasBeenStarted, isFalse);
    expect(controller.remainingMs, 90000);
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
