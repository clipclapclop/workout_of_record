import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/calendar_data.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../workout_units.dart';
import 'calendar_cell_widget.dart';
import 'load_failure_view.dart';

void showMesoCalendarSheet(
  BuildContext context,
  int mesocycleId,
  int currentCompletedWorkoutId, {
  Future<MesocycleCalendar> Function(int)? loadCalendar,
  Future<WorkoutData> Function(int)? loadWorkout,
  Future<List<String>> Function(CalendarCell)? loadUpcomingExercises,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MesoCalendarSheet(
      mesocycleId: mesocycleId,
      currentCompletedWorkoutId: currentCompletedWorkoutId,
      loadCalendar: loadCalendar ?? db.getMesocycleCalendar,
      loadWorkout: loadWorkout ?? db.getWorkoutData,
      loadUpcomingExercises: loadUpcomingExercises,
    ),
  );
}

class _RetryableSheetLoad<T> extends StatefulWidget {
  const _RetryableSheetLoad({
    required this.initialChildSize,
    required this.minChildSize,
    required this.message,
    required this.load,
    required this.contentBuilder,
  });

  final double initialChildSize;
  final double minChildSize;
  final String message;
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, ScrollController) contentBuilder;

  @override
  State<_RetryableSheetLoad<T>> createState() =>
      _RetryableSheetLoadState<T>();
}

class _RetryableSheetLoadState<T> extends State<_RetryableSheetLoad<T>> {
  Future<T>? _future;

  void _retry() {
    setState(() => _future = null);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        final future = _future ??= Future.sync(widget.load);
        return FutureBuilder<T>(
          future: future,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return LoadFailureView(
                message: widget.message,
                onRetry: _retry,
                onClose: () => Navigator.pop(context),
              );
            }
            return widget.contentBuilder(
              ctx,
              snapshot.data as T,
              scrollController,
            );
          },
        );
      },
    );
  }
}

class _MesoCalendarSheet extends StatelessWidget {
  const _MesoCalendarSheet({
    required this.mesocycleId,
    required this.currentCompletedWorkoutId,
    required this.loadCalendar,
    required this.loadWorkout,
    this.loadUpcomingExercises,
  });

  final int mesocycleId;
  final int currentCompletedWorkoutId;
  final Future<MesocycleCalendar> Function(int) loadCalendar;
  final Future<WorkoutData> Function(int) loadWorkout;
  final Future<List<String>> Function(CalendarCell)? loadUpcomingExercises;

  @override
  Widget build(BuildContext context) {
    return _RetryableSheetLoad<MesocycleCalendar>(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      message: 'Couldn’t load the mesocycle calendar.',
      load: () => loadCalendar(mesocycleId),
      contentBuilder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, MesocycleCalendar cal,
      ScrollController scrollController) {
    final maxRows = cal.weeks.fold(
        0, (m, w) => w.cells.length > m ? w.cells.length : m);

    const cellW = 96.0;
    const cellH = 72.0;
    const headerH = 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(cal.mesoName,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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
                        highlightId: currentCompletedWorkoutId,
                        onTap: () => _onCellTap(context, cell),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onCellTap(BuildContext context, CalendarCell cell) {
    final cw = cell.completedWorkout;
    if (cw != null && cw.id == currentCompletedWorkoutId) {
      Navigator.pop(context);
      return;
    }
    if (cw != null) {
      _showCompletedDetail(context, cell, cw);
    } else {
      _showUpcomingDetail(context, cell);
    }
  }

  // ── Completed workout detail ────────────────────────────────────────────────

  void _showCompletedDetail(
      BuildContext context, CalendarCell cell, CompletedWorkout cw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RetryableSheetLoad<WorkoutData>(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        message: 'Couldn’t load this completed workout.',
        load: () => loadWorkout(cw.id),
        contentBuilder: (ctx, data, scroll) =>
            _buildCompletedDetail(ctx, cell, data, scroll),
      ),
    );
  }

  Widget _buildCompletedDetail(BuildContext context, CalendarCell cell,
      WorkoutData data, ScrollController scroll) {
    final cw = data.completedWorkout;
    const weightUnit = WorkoutUnits.weight;

    Widget body;
    if (cw.status == WorkoutStatus.skipped) {
      final reason =
          cw.skipReason != null ? ' — ${_workoutSkipLabel(cw.skipReason!)}' : '';
      body = Center(
          child: Text('Workout skipped$reason',
              style: Theme.of(context).textTheme.bodyLarge));
    } else if (data.exercises.isEmpty) {
      body = const Center(child: Text('No exercises recorded.'));
    } else {
      body = ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          for (final ex in data.exercises)
            _buildExercise(context, ex, weightUnit),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cell.workoutName,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(_formatDate(cw.startedAt),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }

  // ── Upcoming workout detail (materialized or template) ─────────────────────

  void _showUpcomingDetail(BuildContext context, CalendarCell cell) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RetryableSheetLoad<List<String>>(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        message: 'Couldn’t load this upcoming workout.',
        load: () => loadUpcomingExercises?.call(cell) ??
            _loadUpcomingExercises(cell),
        contentBuilder: (ctx, exercises, scroll) =>
            _buildUpcomingDetail(ctx, cell, exercises, scroll),
      ),
    );
  }

  Future<List<String>> _loadUpcomingExercises(CalendarCell cell) async {
    if (cell.workoutTemplateId != null) {
      return db.getTemplateExerciseNames(cell.workoutTemplateId!);
    }
    if (cell.workoutId != null) {
      final entries = await db.getPlannedExerciseList(cell.workoutId!);
      return entries.map((e) => e.movementName).toList();
    }
    return [];
  }

  Widget _buildUpcomingDetail(BuildContext context, CalendarCell cell,
      List<String> exercises, ScrollController scroll) {
    Widget body;
    if (exercises.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Exercises will be selected before this workout.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          for (final name in exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(name,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cell.workoutName,
                  style: Theme.of(context).textTheme.titleMedium),
              Text('Upcoming',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _handle(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildExercise(
      BuildContext context, ExerciseData ex, String weightUnit) {
    final isSkipped = ex.completed.skipReason != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ex.movement.name,
              style: Theme.of(context).textTheme.titleSmall),
          if (isSkipped)
            Text(
              'Skipped — ${_exSkipLabel(ex.completed.skipReason!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else
            for (var i = 0; i < ex.sets.length; i++)
              _buildSetRow(
                  context, i + 1, ex.sets[i], ex.movement, weightUnit),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int setNum, SetData s, Movement m,
      String weightUnit) {
    final cs = s.completed;
    final ps = s.planned;
    final isSkipped = cs.skipReason != null;

    String fmt(double? v) {
      if (v == null) return '—';
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    }

    String setVal(
        int? reps, double? weight, double? distance, double? time) {
      final parts = <String>[];
      if (m.isRequiredReps) parts.add(reps != null ? '$reps reps' : '—');
      if (m.isRequiredWeight) {
        parts.add(weight != null ? '${fmt(weight)} $weightUnit' : '—');
      }
      if (m.isRequiredDistance) {
        parts.add(distance != null
            ? '${fmt(distance)} ${WorkoutUnits.distance}'
            : '—');
      }
      if (m.isRequiredTime) parts.add(time != null ? '${fmt(time)}s' : '—');
      return parts.isEmpty ? '—' : parts.join(' × ');
    }

    final plannedStr = ps != null
        ? setVal(ps.reps, ps.weight, ps.distance, ps.time)
        : '—';
    final completedStr = isSkipped
        ? 'Skipped — ${_exSkipLabel(cs.skipReason!)}'
        : setVal(cs.reps, cs.weight, cs.distance, cs.time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text('Set $setNum',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
              child: Text(plannedStr,
                  style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: Text(
              completedStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSkipped
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _workoutSkipLabel(WorkoutSkipReason r) => switch (r) {
        WorkoutSkipReason.time => 'Time',
        WorkoutSkipReason.soreness => 'Soreness',
        WorkoutSkipReason.illness => 'Illness',
        WorkoutSkipReason.other => 'Other',
      };

  String _exSkipLabel(SkipReason r) => switch (r) {
        SkipReason.systemicFatigue => 'Systemic Fatigue',
        SkipReason.muscleFatigue => 'Muscle Fatigue',
        SkipReason.jointPain => 'Joint Pain',
        SkipReason.time => 'Time',
        SkipReason.musclePain => 'Muscle Pain',
        SkipReason.softTissuePainOther => 'Soft Tissue / Other',
        SkipReason.dontLikeTheExercise => "Don't Like the Exercise",
      };
}
