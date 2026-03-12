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
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final cw = item.completedWorkout;
              final d = cw.startedAt;
              final dateStr =
                  '${_monthName(d.month)} ${d.day}, ${d.year}';
              final isSkipped = cw.status == WorkoutStatus.skipped;

              return ListTile(
                title: Text('${item.workoutName}  ·  Week ${item.weekNumber}'),
                subtitle: Text('${item.mesoName}  ·  $dateStr'),
                trailing: isSkipped
                    ? Chip(
                        label: const Text('Skipped'),
                        backgroundColor:
                            Theme.of(context).colorScheme.errorContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutHistoryDetailScreen(
                      completedWorkoutId: cw.id,
                      title: '${item.workoutName} — Week ${item.weekNumber}',
                      activeWorkoutId: activeWorkoutId,
                      activeWorkoutName: activeWorkoutName,
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
