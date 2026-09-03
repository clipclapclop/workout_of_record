import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../services/workout_foreground_service.dart';
import '../services/workout_recovery_service.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/load_failure_view.dart';
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
  final MesoProgressInfo progress;
  _WorkoutReady(this.workout, this.expectedDate, this.progress);
}

/// An exact active attempt exists, but its complete workout data did not load.
class _DamagedActiveWorkout extends _HomeResult {
  final ActiveWorkoutReference active;
  _DamagedActiveWorkout(this.active);
}

// ── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.reconcileActiveWorkout,
    this.loadActiveWorkout,
    this.resetActiveWorkout,
    this.clearWorkoutRuntimeState,
    this.activeWorkoutBuilder,
  });

  final Future<ActiveWorkoutReference?> Function()? reconcileActiveWorkout;
  final Future<WorkoutData> Function(int)? loadActiveWorkout;
  final Future<void> Function(int)? resetActiveWorkout;
  final Future<void> Function()? clearWorkoutRuntimeState;
  final Widget Function(ActiveWorkoutReference, WorkoutData)?
      activeWorkoutBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeResult> _resultFuture;
  bool _resettingWorkout = false;
  String? _resetWorkoutError;

  @override
  void initState() {
    super.initState();
    _resultFuture = _init();
  }

  void _retryLoad() {
    setState(() {
      _resetWorkoutError = null;
      _resultFuture = _init();
    });
  }

  Future<_HomeResult> _init() async {
    final active = await (widget.reconcileActiveWorkout?.call() ??
        WorkoutRecoveryService.reconcileNavigationPointers(db));

    // Resume an in-progress workout if one exists. A failure after the exact
    // attempt is known receives narrowly scoped recovery rather than exposing
    // a destructive action for every possible Home loading error.
    if (active != null) {
      late WorkoutData data;
      try {
        data = await (widget.loadActiveWorkout?.call(
              active.completedWorkoutId,
            ) ??
            db.getWorkoutData(active.completedWorkoutId));
      } catch (_) {
        return _DamagedActiveWorkout(active);
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: WorkoutScreen.routeName),
              builder: (_) => widget.activeWorkoutBuilder?.call(active, data) ??
                  WorkoutScreen(
                    completedWorkoutId: active.completedWorkoutId,
                    workoutName: data.workout.name,
                    mesocycleId: active.mesocycleId,
                    initialData: data,
                  ),
            ),
          );
        });
      }
      return _Redirecting();
    }

    // Also repairs a crash after a workout was durably reset but before its
    // cached timer and Android foreground-service state could be cleared.
    await _clearWorkoutRuntimeState();

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
    final progress = await db.getMesoProgress(mesocycleId, workout.id);
    return _WorkoutReady(workout, date, progress);
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

  String _formatProgress(MesoProgressInfo p) {
    final base = 'Week ${p.weekNumber} of ${p.totalWeekCount} · '
        'Day ${p.trainingDayIndex} of ${p.totalTrainingDaysThisWeek}';
    return p.isDeloadWeek ? '$base · Deload' : base;
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

  Future<void> _changeMesoLength(BuildContext context,
      {required bool add}) async {
    final mesoId = AppPreferences.getCurrentMesocycleId();
    if (mesoId == null) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (add) {
        await db.addHardWeek(mesoId);
      } else {
        await db.removeWeek(mesoId);
      }
    } on StateError {
      // Lost a race against state change — just refresh.
      if (mounted) setState(() => _resultFuture = _init());
      return;
    }
    if (!mounted) return;
    setState(() => _resultFuture = _init());

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(add ? 'Hard week added.' : 'Week removed.'),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => _changeMesoLength(context, add: !add),
      ),
    ));
  }

  Future<void> _endMesocycleEarly() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Mesocycle Early?'),
        content: const Text(
          'Your completed workouts will be preserved, but remaining '
          'workouts will not be created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Mesocycle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final mesoId = AppPreferences.getCurrentMesocycleId();
    if (mesoId != null) await db.endMesocycleEarly(mesoId);
    await _startNewMesocycle();
  }

  Future<void> _startNewMesocycle() async {
    await AppPreferences.setCurrentMesocycleId(null);
    await AppPreferences.setCurrentCompletedWorkoutId(null);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MesocycleSetupScreen()),
    );
  }

  Future<void> _clearWorkoutRuntimeState() async {
    if (widget.clearWorkoutRuntimeState != null) {
      await widget.clearWorkoutRuntimeState!();
      return;
    }
    await AppPreferences.setCurrentCompletedWorkoutId(null);
    await AppPreferences.clearActiveRestTimer();
    await WorkoutForegroundService.stop();
  }

  Future<void> _resetDamagedWorkout(ActiveWorkoutReference active) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset this workout?'),
        content: Text(
          'This permanently removes the in-progress sets, feedback, and '
          'pre-workout check-in for ${active.workoutName}. The scheduled '
          'workout and completed history will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Workout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _resettingWorkout = true;
      _resetWorkoutError = null;
    });
    try {
      await (widget.resetActiveWorkout?.call(active.completedWorkoutId) ??
          db.resetActiveWorkout(active.completedWorkoutId));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resettingWorkout = false;
        _resetWorkoutError = 'Couldn’t reset this workout. Try again.';
      });
      return;
    }

    try {
      await _clearWorkoutRuntimeState();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resettingWorkout = false;
        _resetWorkoutError =
            'The workout was reset, but cleanup was incomplete. Tap Retry.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _resettingWorkout = false;
      _resetWorkoutError = null;
      _resultFuture = _init();
    });
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
            return LoadFailureView(
              message: 'Couldn’t load your current workout.',
              onRetry: _retryLoad,
            );
          }

          return switch (snapshot.data!) {
            _Redirecting() => const Center(child: CircularProgressIndicator()),
            _MesoComplete() => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mesocycle\nComplete!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You've finished every workout in this block.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton(
                      onPressed: _startNewMesocycle,
                      child: const Text('Start New Mesocycle'),
                    ),
                  ],
                ),
              ),
            _DamagedActiveWorkout(:final active) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Couldn’t reopen this workout',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      active.workoutName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Started ${_formatExpectedDate(active.startedAt)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Retry first. If this saved attempt is damaged, reset it '
                      'to start the same scheduled workout again.',
                      textAlign: TextAlign.center,
                    ),
                    if (_resetWorkoutError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _resetWorkoutError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _resettingWorkout ? null : _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _resettingWorkout
                          ? null
                          : () => _resetDamagedWorkout(active),
                      child: const Text('Reset Workout'),
                    ),
                    if (_resettingWorkout) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            _WorkoutReady(
              :final workout,
              :final expectedDate,
              :final progress,
            ) =>
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (expectedDate != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatExpectedDate(expectedDate),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _formatProgress(progress),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      workout.name,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton(
                      onPressed: () => _startWorkout(workout),
                      child: const Text('Start Workout'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _skipWorkout(workout),
                      child: const Text('Skip Workout'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: progress.canAddHardWeek
                              ? () => _changeMesoLength(context, add: true)
                              : null,
                          child: const Text('Add Hard Week'),
                        ),
                        TextButton(
                          onPressed: progress.canRemoveWeek
                              ? () => _changeMesoLength(context, add: false)
                              : null,
                          child: const Text('Remove a Week'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _endMesocycleEarly,
                      child: const Text('End Mesocycle Early'),
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
