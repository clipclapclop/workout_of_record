import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../widgets/app_nav_menu.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  const WorkoutHistoryDetailScreen({
    super.key,
    required this.completedWorkoutId,
    required this.title,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int completedWorkoutId;
  final String title;
  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          AppNavMenu(
            current: AppScreen.history,
            activeWorkoutId: activeWorkoutId,
            activeWorkoutName: activeWorkoutName,
          ),
        ],
      ),
      body: FutureBuilder<WorkoutData>(
        future: db.getWorkoutData(completedWorkoutId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final cw = data.completedWorkout;

          if (cw.status == WorkoutStatus.skipped) {
            final reason =
                cw.skipReason != null ? ' — ${_workoutSkipLabel(cw.skipReason!)}' : '';
            return Center(
              child: Text(
                'Workout skipped$reason',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          if (data.exercises.isEmpty) {
            return const Center(child: Text('No exercises recorded.'));
          }

          final weightUnit = AppPreferences.getUnitsMetric() ? 'kg' : 'lbs';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final ex in data.exercises)
                _buildExercise(context, ex, weightUnit),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExercise(
      BuildContext context, ExerciseData ex, String weightUnit) {
    final isSkipped = ex.completed.skipReason != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ex.movement.name,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (isSkipped)
            Text(
              'Skipped — ${_exSkipLabel(ex.completed.skipReason!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Text('Planned',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                  Expanded(
                    child: Text('Done',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < ex.sets.length; i++)
              _buildSetRow(context, i + 1, ex.sets[i], ex.movement, weightUnit),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, int setNum, SetData s,
      Movement m, String weightUnit) {
    final cs = s.completed;
    final ps = s.planned;
    final isSkipped = cs.skipReason != null;

    String fmt(double? v) {
      if (v == null) return '—';
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    }

    String setVal(int? reps, double? weight, double? time) {
      final parts = <String>[];
      if (m.isRequiredReps) parts.add(reps != null ? '$reps reps' : '—');
      if (m.isRequiredWeight) {
        parts.add(weight != null ? '${fmt(weight)} $weightUnit' : '—');
      }
      if (m.isRequiredTime) parts.add(time != null ? '${fmt(time)}s' : '—');
      return parts.join(' × ');
    }

    final plannedStr = ps != null ? setVal(ps.reps, ps.weight, ps.time) : '—';
    final completedStr = isSkipped
        ? 'Skipped — ${_exSkipLabel(cs.skipReason!)}'
        : setVal(cs.reps, cs.weight, cs.time);

    return Container(
      decoration: isSkipped
          ? BoxDecoration(
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text('Set $setNum',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(plannedStr,
                style: Theme.of(context).textTheme.bodySmall),
          ),
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
