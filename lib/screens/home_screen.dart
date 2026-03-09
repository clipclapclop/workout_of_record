import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'mesocycle_setup_screen.dart';
import 'pre_workout_checkin_screen.dart';
import 'profile_screen.dart';
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

  /// Validates the SharedPreferences acceleration pointers against DB ground
  /// truth and clears any stale values so they are never misleading.
  Future<void> _reconcile() async {
    final completedWorkoutId = AppPreferences.getCurrentCompletedWorkoutId();
    if (completedWorkoutId != null) {
      final row = await (db.select(db.completedWorkouts)
            ..where((w) => w.id.equals(completedWorkoutId)))
          .getSingleOrNull();
      final isActive = row != null &&
          row.completedAt == null &&
          row.status == WorkoutStatus.active;
      if (!isActive) await AppPreferences.setCurrentCompletedWorkoutId(null);
    }

    final mesocycleId = AppPreferences.getCurrentMesocycleId();
    if (mesocycleId != null) {
      final row = await (db.select(db.mesocycles)
            ..where((m) => m.id.equals(mesocycleId)))
          .getSingleOrNull();
      if (row == null) await AppPreferences.setCurrentMesocycleId(null);
    }
  }

  Future<_HomeResult> _init() async {
    await _reconcile();

    // Resume in-progress workout if one exists.
    final activeId = AppPreferences.getCurrentCompletedWorkoutId();
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

    // No active mesocycle — cold boot or meso complete.
    final mesocycleId = AppPreferences.getCurrentMesocycleId();
    if (mesocycleId == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _handleNomesocycle();
        });
      }
      return _Redirecting();
    }

    final workout = await db.getOrCreateNextWorkout(mesocycleId);
    if (workout == null) return _MesoComplete();

    final date = await db.getExpectedWorkoutDate(mesocycleId);
    return _WorkoutReady(workout, date);
  }

  /// On fresh install (no mesocycle), optionally prompt to set up profile first.
  Future<void> _handleNomesocycle() async {
    if (!AppPreferences.hasSeenProfilePrompt()) {
      await AppPreferences.setHasSeenProfilePrompt(true);
      if (!mounted) return;
      final goToProfile = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Up Your Profile'),
          content: const Text(
            'Your profile helps the AI make better workout recommendations '
            '— things like your age, weight, and training goal. '
            'Would you like to set it up now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set Up Profile'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (goToProfile == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        if (!mounted) return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MesocycleSetupScreen()),
    );
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
    await AppPreferences.setCurrentMesocycleId(null);
    await AppPreferences.setCurrentCompletedWorkoutId(null);
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
