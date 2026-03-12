import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/history_data.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'workout_history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.history,
            activeWorkoutId: activeWorkoutId,
            activeWorkoutName: activeWorkoutName,
          ),
        ],
      ),
      body: FutureBuilder<List<CompletedWorkoutSummary>>(
        future: db.getCompletedWorkoutSummaries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No workouts yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final cw = item.completedWorkout;
              final d = cw.startedAt;
              final dateStr = '${_monthName(d.month)} ${d.day}, ${d.year}';
              final isSkipped = cw.status == WorkoutStatus.skipped;

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    item.workoutName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.mesoName}  ·  Week ${item.weekNumber}  ·  $dateStr',
                  ),
                  trailing: isSkipped
                      ? Chip(
                          label: const Text('Skipped'),
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : Icon(
                          Icons.chevron_right,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutHistoryDetailScreen(
                        completedWorkoutId: cw.id,
                        title:
                            '${item.workoutName} — Week ${item.weekNumber}',
                        activeWorkoutId: activeWorkoutId,
                        activeWorkoutName: activeWorkoutName,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _monthName(int month) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month];
}
