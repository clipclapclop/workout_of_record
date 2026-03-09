import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'mesocycle_setup_screen.dart';
import 'pre_workout_checkin_screen.dart';
import 'workout_screen.dart';

// ── Home state ───────────────────────────────────────────────────────────────

sealed class _HomeResult {}

/// Navigation is about to happen via addPostFrameCallback — show spinner.
class _Redirecting extends _HomeResult {}

/// All workouts in the mesocycle are complete.
class _MesoComplete extends _HomeResult {}

/// A workout is ready to start or scheduled.
class _WorkoutReady extends _HomeResult {
  final Workout workout;
  final DateTime? expectedDate;
  _WorkoutReady(this.workout, this.expectedDate);
}

// ── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeResult> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _init();
  }

  /// Resolves app state and returns a [_HomeResult] describing what to show.
  ///
  /// Redirect cases schedule navigation via addPostFrameCallback (safe from
  /// initState) and return [_Redirecting] so the spinner stays visible until
  /// the route transition fires — no flash of the wrong screen.
  Future<_HomeResult> _init() async {
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
      return _Redirecting();
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
      return _Redirecting();
    }

    final workout = await db.getOrCreateNextWorkout(mesocycleId);
    if (workout == null) return _MesoComplete();

    final date = await db.getExpectedWorkoutDate(mesocycleId);
    return _WorkoutReady(workout, date);
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
    setState(() => _resultFuture = _init());
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
    setState(() => _resultFuture = _init());
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
      body: FutureBuilder<_HomeResult>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return switch (snapshot.data!) {
            _Redirecting() => const Center(child: CircularProgressIndicator()),
            _MesoComplete() => Center(
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
              ),
            _WorkoutReady(:final workout, :final expectedDate) => Center(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
              ),
          };
        },
      ),
    );
  }
}
