import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
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
  late Future<Workout?> _nextWorkoutFuture;

  @override
  void initState() {
    super.initState();
    _nextWorkoutFuture = _init();
  }

  /// Resolves app state and returns the next workout to display, or null.
  ///
  /// Side-effects (routing) are deferred via addPostFrameCallback so this
  /// method is safe to call from initState.
  Future<Workout?> _init() async {
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
      return null;
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
      return null;
    }

    return db.getOrCreateNextWorkout(mesocycleId);
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
    setState(() {
      _nextWorkoutFuture = _init();
    });
  }

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
      body: FutureBuilder<Workout?>(
        future: _nextWorkoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final workout = snapshot.data;

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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _startWorkout(workout),
                  child: const Text('Start Workout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
