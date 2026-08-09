import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/calendar_data.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/screens/history_screen.dart';
import 'package:workout_of_record/widgets/calendar_cell_widget.dart';

AppDatabase _openDb() => AppDatabase.withExecutor(NativeDatabase.memory());

Future<int> _createMeso(AppDatabase database, String name) async {
  final templates = await database.getMesoTemplates();
  return database.createMesocycle(templates.first.id, name, 2);
}

Future<(int, int)> _startNextWorkout(
  AppDatabase database,
  int mesocycleId,
) async {
  final workout = await database.getOrCreateNextWorkout(mesocycleId);
  await database.generatePlannedWorkout(workout!.id);
  final completedWorkoutId = await database.initializeWorkout(workout.id);
  return (workout.id, completedWorkoutId);
}

void main() {
  test(
    'history mesocycle IDs include active cycles and exclude unstarted cycles',
    () async {
      final database = _openDb();
      addTearDown(database.close);

      final completedMesoId = await _createMeso(database, 'Completed activity');
      final (_, completedWorkoutId) = await _startNextWorkout(
        database,
        completedMesoId,
      );
      await (database.update(
        database.completedWorkouts,
      )..where((row) => row.id.equals(completedWorkoutId))).write(
        CompletedWorkoutsCompanion(startedAt: Value(DateTime.utc(2026, 1, 1))),
      );
      await database.finishWorkout(completedWorkoutId);

      final activeMesoId = await _createMeso(database, 'Active activity');
      final (_, activeWorkoutId) = await _startNextWorkout(
        database,
        activeMesoId,
      );
      await (database.update(
        database.completedWorkouts,
      )..where((row) => row.id.equals(activeWorkoutId))).write(
        CompletedWorkoutsCompanion(startedAt: Value(DateTime.utc(2026, 1, 2))),
      );

      await _createMeso(database, 'No activity');

      expect(await database.getMesocycleIdsWithWorkoutHistory(), [
        activeMesoId,
        completedMesoId,
      ]);
    },
  );

  testWidgets(
    'History shows completed, active, skipped, and future workout states',
    (tester) async {
      final startedAt = DateTime.utc(2026, 1, 1);
      final completedWorkout = CompletedWorkout(
        id: 101,
        workoutId: 11,
        startedAt: startedAt,
        completedAt: startedAt.add(const Duration(hours: 1)),
        status: WorkoutStatus.completed,
      );
      final activeWorkout = CompletedWorkout(
        id: 102,
        workoutId: 12,
        startedAt: startedAt.add(const Duration(days: 1)),
        status: WorkoutStatus.active,
      );
      final skippedWorkout = CompletedWorkout(
        id: 103,
        workoutId: 13,
        startedAt: startedAt.subtract(const Duration(days: 1)),
        completedAt: startedAt.subtract(const Duration(days: 1)),
        status: WorkoutStatus.skipped,
        skipReason: WorkoutSkipReason.other,
      );
      final calendar = MesocycleCalendar(
        mesoName: 'Current mesocycle',
        totalWeekCount: 1,
        weeks: [
          CalendarWeek(
            weekNumber: 1,
            goal: WeekGoal.hard,
            cells: [
              CalendarCell(
                workoutId: 11,
                workoutName: 'Monday',
                orderIndex: 0,
                completedWorkout: completedWorkout,
              ),
              CalendarCell(
                workoutId: 12,
                workoutName: 'Tuesday',
                orderIndex: 1,
                completedWorkout: activeWorkout,
              ),
              CalendarCell(
                workoutId: 13,
                workoutName: 'Wednesday',
                orderIndex: 2,
                completedWorkout: skippedWorkout,
              ),
              const CalendarCell(workoutName: 'Thursday', orderIndex: 3),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(
            activeWorkoutId: activeWorkout.id,
            activeWorkoutName: 'Tuesday',
            loadCalendars: () async => [calendar],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current mesocycle'), findsOneWidget);

      final completedCell = find.byWidgetPredicate(
        (widget) =>
            widget is CalendarCellWidget &&
            widget.cell.completedWorkout?.id == completedWorkout.id,
      );
      final activeCell = find.byWidgetPredicate(
        (widget) =>
            widget is CalendarCellWidget &&
            widget.cell.completedWorkout?.id == activeWorkout.id,
      );
      final skippedCell = find.byWidgetPredicate(
        (widget) =>
            widget is CalendarCellWidget &&
            widget.cell.completedWorkout?.id == skippedWorkout.id,
      );
      final futureCell = find.byWidgetPredicate(
        (widget) =>
            widget is CalendarCellWidget &&
            widget.cell.completedWorkout == null,
      );

      expect(completedCell, findsOneWidget);
      expect(activeCell, findsOneWidget);
      expect(skippedCell, findsOneWidget);
      expect(futureCell, findsOneWidget);
      expect(
        find.descendant(of: completedCell, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: activeCell,
          matching: find.byIcon(Icons.play_arrow),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skippedCell,
          matching: find.byIcon(Icons.skip_next),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: futureCell, matching: find.byType(Icon)),
        findsNothing,
      );

      final colorScheme = Theme.of(
        tester.element(find.byType(HistoryScreen)),
      ).colorScheme;
      expect(
        _backgroundColor(tester, completedCell),
        Colors.green.withValues(alpha: 0.15),
      );
      expect(_backgroundColor(tester, activeCell), colorScheme.errorContainer);
      expect(
        _backgroundColor(tester, skippedCell),
        colorScheme.errorContainer.withValues(alpha: 0.5),
      );
      expect(
        _backgroundColor(tester, futureCell),
        colorScheme.surfaceContainerHighest,
      );
    },
  );
}

Color? _backgroundColor(WidgetTester tester, Finder cell) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: cell,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color;
}
