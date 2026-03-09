import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'mesocycle_setup_screen.dart';
import 'pre_workout_checkin_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(Workout?, DateTime?)> _nextWorkoutFuture;

  @override
  void initState() {
    super.initState();
    _nextWorkoutFuture = _init();
  }

  /// Resolves app state and returns the next workout + expected date, or nulls.
  ///
  /// Side-effects (routing) are deferred via addPostFrameCallback so this
  /// method is safe to call from initState.
  Future<(Workout?, DateTime?)> _init() async {
    final appState = await db.getAppState();

    // Resume in-progress workout if one exists.
    final activeId = appState.currentCompletedWorkoutId;
    if (activeId != null) {
      final data = await db.getWorkoutData(activeId);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutScreen(
                completedWorkoutId: activeId,
                workoutName: data.workout.name,
              ),
            ),
          );
        });
      }
      return (null, null);
    }

    // No active mesocycle — send to setup.
    final mesocycleId = appState.currentMesocycleId;
    if (mesocycleId == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MesocycleSetupScreen()),
          );
        });
      }
      return (null, null);
    }

    final workout = await db.getOrCreateNextWorkout(mesocycleId);
    final date = workout != null
        ? await db.getExpectedWorkoutDate(mesocycleId)
        : null;
    return (workout, date);
  }

  Future<void> _startWorkout(Workout workout) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreWorkoutCheckinScreen(
          workoutId: workout.id,
          workoutName: workout.name,
        ),
      ),
    );
    setState(() => _nextWorkoutFuture = _init());
  }

  Future<void> _skipWorkout(Workout workout) async {
    WorkoutSkipReason? selected;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skip Workout', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final reason in WorkoutSkipReason.values)
              ListTile(
                title: Text(_skipReasonLabel(reason)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  selected = reason;
                  Navigator.pop(ctx);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await db.skipWorkout(workout.id, selected!);
    setState(() => _nextWorkoutFuture = _init());
  }

  String _formatExpectedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _skipReasonLabel(WorkoutSkipReason r) => switch (r) {
        WorkoutSkipReason.time => 'Time',
        WorkoutSkipReason.soreness => 'Soreness',
        WorkoutSkipReason.illness => 'Illness',
        WorkoutSkipReason.other => 'Other',
      };

  Future<void> _startNewMesocycle() async {
    await db.clearCurrentMesocycle();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MesocycleSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout of Record'),
        actions: [
          AppNavMenu(current: AppScreen.workout),
        ],
      ),
      body: FutureBuilder<(Workout?, DateTime?)>(
        future: _nextWorkoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final (workout, expectedDate) = snapshot.data ?? (null, null);

          // null means either routing is in progress (resume/setup) or meso complete.
          if (workout == null) {
            // If we got here without a redirect, the mesocycle is complete.
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Mesocycle Complete!',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _startNewMesocycle,
                    child: const Text('Start New Mesocycle'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(workout.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (expectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatExpectedDate(expectedDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _startWorkout(workout),
                  child: const Text('Start Workout'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _skipWorkout(workout),
                  child: const Text('Skip Workout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
