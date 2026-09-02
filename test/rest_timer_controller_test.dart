import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/widgets/rest_timer_controller.dart';

void main() {
  test('duration changes do not restart or replace a running countdown', () {
    final controller = RestTimerController(durationSeconds: 60);
    addTearDown(controller.dispose);

    expect(controller.isRunning, isFalse);
    controller.start();
    controller.setDurationWhenIdle(90);

    expect(controller.isRunning, isTrue);
    expect(controller.durationSeconds, 60);

    controller.stop();
    controller.setDurationWhenIdle(90);
    expect(controller.isRunning, isFalse);
    expect(controller.durationSeconds, 90);
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
