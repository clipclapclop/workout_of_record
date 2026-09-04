import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/screens/home_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('successful workout skip refreshes Home without a framework error',
      (tester) async {
    await initializeTestPreferences();
    await AppPreferences.setCurrentMesocycleId(1);
    var nextWorkoutCalls = 0;
    WorkoutSkipReason? savedReason;

    Workout workout(String name, int id) => Workout(
          id: id,
          weekId: 1,
          name: name,
          orderIndex: id,
          isRestDay: false,
        );

    const progress = MesoProgressInfo(
      weekNumber: 1,
      totalWeekCount: 2,
      trainingDayIndex: 1,
      totalTrainingDaysThisWeek: 2,
      isDeloadWeek: false,
      canAddHardWeek: true,
      canRemoveWeek: false,
    );

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => null,
          clearWorkoutRuntimeState: () async {},
          getNextWorkout: (_) async {
            nextWorkoutCalls++;
            return nextWorkoutCalls == 1
                ? workout('Monday', 1)
                : workout('Tuesday', 2);
          },
          getExpectedWorkoutDate: (_) async => null,
          getMesoProgress: (_, _) async => progress,
          skipWorkout: (_, reason) async => savedReason = reason,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monday'), findsOneWidget);
    await tester.tap(find.text('Skip Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Illness'));
    await tester.pumpAndSettle();

    expect(savedReason, WorkoutSkipReason.illness);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
