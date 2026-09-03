import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/workout_data.dart';
import 'package:workout_of_record/screens/home_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('identified active workout gets focused recovery and can retry', (
    tester,
  ) async {
    await initializeTestPreferences();
    final active = _activeReference();
    var loadCalls = 0;

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => active,
          loadActiveWorkout: (_) async {
            loadCalls++;
            if (loadCalls == 1) {
              throw const WorkoutDataIntegrityException();
            }
            return _workoutData(active);
          },
          activeWorkoutBuilder: (_, _) =>
              const Scaffold(body: Text('Recovered workout')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t reopen this workout'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('Reset Workout'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered workout'), findsOneWidget);
    expect(loadCalls, 2);
  });

  testWidgets('transient active-workout failures remain retry-only', (
    tester,
  ) async {
    await initializeTestPreferences();
    final active = _activeReference();

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => active,
          loadActiveWorkout: (_) async => throw Exception('temporary read'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load your current workout.'), findsOneWidget);
    expect(find.text('Reset Workout'), findsNothing);
    expect(find.textContaining('temporary read'), findsNothing);
  });

  testWidgets('startup clears stale runtime state when no workout is active', (
    tester,
  ) async {
    await initializeTestPreferences();
    var cleanupStarted = false;

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => null,
          clearWorkoutRuntimeState: () {
            cleanupStarted = true;
            return Future<void>.value();
          },
        ),
      ),
    );
    await tester.pump();

    expect(cleanupStarted, isTrue);
  });

  testWidgets('generic Home failures never offer destructive recovery', (
    tester,
  ) async {
    await initializeTestPreferences();
    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => throw Exception('database down'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load your current workout.'), findsOneWidget);
    expect(find.text('Reset Workout'), findsNothing);
    expect(find.textContaining('database down'), findsNothing);
  });

  testWidgets('cancelled and failed resets do not clear workout state', (
    tester,
  ) async {
    await initializeTestPreferences();
    final active = _activeReference();
    var resetCalls = 0;
    var clearCalls = 0;

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => active,
          loadActiveWorkout: (_) async =>
              throw const WorkoutDataIntegrityException(),
          resetActiveWorkout: (_) async {
            resetCalls++;
            throw Exception('write failed');
          },
          clearWorkoutRuntimeState: () async => clearCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(resetCalls, 0);
    expect(clearCalls, 0);

    await tester.tap(find.text('Reset Workout'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Reset Workout')),
    );
    await tester.pumpAndSettle();

    expect(resetCalls, 1);
    expect(clearCalls, 0);
    expect(
      find.text('Couldn’t reset this workout. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('successful reset clears transient state after the database', (
    tester,
  ) async {
    await initializeTestPreferences();
    final active = _activeReference();
    final events = <String>[];

    await tester.pumpWidget(
      buildTestApp(
        home: HomeScreen(
          reconcileActiveWorkout: () async => active,
          loadActiveWorkout: (_) async =>
              throw const WorkoutDataIntegrityException(),
          resetActiveWorkout: (_) async => events.add('database'),
          clearWorkoutRuntimeState: () async => events.add('transient state'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Workout'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Reset Workout')),
    );
    await tester.pumpAndSettle();

    expect(events, ['database', 'transient state']);
  });
}

ActiveWorkoutReference _activeReference() => ActiveWorkoutReference(
  completedWorkoutId: 12,
  workoutId: 7,
  workoutName: 'Tuesday',
  startedAt: DateTime(2026, 9, 3, 8),
  mesocycleId: 4,
);

WorkoutData _workoutData(ActiveWorkoutReference active) => WorkoutData(
  completedWorkout: CompletedWorkout(
    id: active.completedWorkoutId,
    workoutId: active.workoutId,
    startedAt: active.startedAt,
    status: WorkoutStatus.active,
  ),
  workout: Workout(
    id: active.workoutId,
    weekId: 5,
    name: active.workoutName,
    orderIndex: 1,
    isRestDay: false,
  ),
  exercises: const [],
  postMuscleGroupCheckins: const [],
);
