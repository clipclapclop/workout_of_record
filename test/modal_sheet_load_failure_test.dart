import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/calendar_data.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/widgets/meso_calendar_sheet.dart';
import 'package:workout_of_record/widgets/past_meso_picker_sheet.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('calendar load failure retries without exposing the error', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      buildTestApp(
        home: _Launcher(
          onOpen: (context) => showMesoCalendarSheet(
            context,
            1,
            -1,
            loadCalendar: (_) async {
              calls++;
              if (calls == 1) throw Exception('private database detail');
              return const MesocycleCalendar(
                mesoName: 'Recovered calendar',
                totalWeekCount: 0,
                weeks: [],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load the mesocycle calendar.'), findsOneWidget);
    expect(find.textContaining('private database detail'), findsNothing);
    expect(calls, 1);

    await tester.pump();
    expect(calls, 1);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered calendar'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('upcoming workout detail can recover inside its own sheet', (
    tester,
  ) async {
    var detailCalls = 0;
    await tester.pumpWidget(
      buildTestApp(
        home: _Launcher(
          onOpen: (context) => showMesoCalendarSheet(
            context,
            1,
            -1,
            loadCalendar: (_) async => const MesocycleCalendar(
              mesoName: 'Training block',
              totalWeekCount: 1,
              weeks: [
                CalendarWeek(
                  weekNumber: 1,
                  goal: WeekGoal.hard,
                  cells: [
                    CalendarCell(
                      workoutName: 'Future day',
                      orderIndex: 0,
                      workoutTemplateId: 3,
                    ),
                  ],
                ),
              ],
            ),
            loadUpcomingExercises: (_) async {
              detailCalls++;
              if (detailCalls == 1) throw Exception('query failed');
              return ['Curl'];
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Future day'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load this upcoming workout.'), findsOneWidget);
    expect(find.textContaining('query failed'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Curl'), findsOneWidget);
    expect(detailCalls, 2);
  });

  testWidgets('past-mesocycle failure supports retry and close', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      buildTestApp(
        home: _Launcher(
          onOpen: (context) => showPastMesoPickerSheet(
            context,
            loadSummaries: () async {
              calls++;
              throw Exception('SQLite internals');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load past mesocycles.'), findsOneWidget);
    expect(find.textContaining('SQLite internals'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Couldn’t load past mesocycles.'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Launcher'), findsOneWidget);
    expect(find.text('Couldn’t load past mesocycles.'), findsNothing);
  });
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.onOpen});

  final void Function(BuildContext) onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Launcher'),
          FilledButton(
            onPressed: () => onOpen(context),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
