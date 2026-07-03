import 'package:flutter/material.dart';

import '../db/calendar_data.dart';
import '../db/db.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/calendar_cell_widget.dart';
import 'workout_history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MesocycleCalendar>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistoryCalendars();
  }

  Future<List<MesocycleCalendar>> _loadHistoryCalendars() async {
    final mesos = await db.getMesocyclesWithCompletedWeeks();
    final calendars = <MesocycleCalendar>[];
    for (final m in mesos) {
      calendars.add(await db.getMesocycleCalendar(m.mesocycle.id));
    }
    return calendars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.history,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
          ),
        ],
      ),
      body: FutureBuilder<List<MesocycleCalendar>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final calendars = snapshot.data!;
          if (calendars.isEmpty) {
            return const Center(child: Text('No workouts yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: calendars.length,
            itemBuilder: (context, i) =>
                _buildMesoBlock(context, calendars[i]),
          );
        },
      ),
    );
  }

  Widget _buildMesoBlock(BuildContext context, MesocycleCalendar cal) {
    final maxRows = cal.weeks.fold(
        0, (m, w) => w.cells.length > m ? w.cells.length : m);

    const cellW = 96.0;
    const cellH = 72.0;
    const headerH = 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(cal.mesoName,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final week in cal.weeks)
                CalendarWeekColumn(
                  week: week,
                  maxRows: maxRows,
                  cellWidth: cellW,
                  cellHeight: cellH,
                  headerHeight: headerH,
                  cellBuilder: (cell, w, h) => CalendarCellWidget(
                    cell: cell,
                    width: w,
                    height: h,
                    onTap: cell.completedWorkout != null
                        ? () => _onCellTap(context, cell, week)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _onCellTap(
      BuildContext context, CalendarCell cell, CalendarWeek week) {
    final cw = cell.completedWorkout!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutHistoryDetailScreen(
          completedWorkoutId: cw.id,
          title: '${cell.workoutName} — Wk ${week.weekNumber}',
          activeWorkoutId: widget.activeWorkoutId,
          activeWorkoutName: widget.activeWorkoutName,
        ),
      ),
    );
  }
}
