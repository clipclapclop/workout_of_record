import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import 'pre_workout_checkin_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Workout?> _nextWorkoutFuture;
  int? _mesocycleId;

  @override
  void initState() {
    super.initState();
    _nextWorkoutFuture = _init();
  }

  /// Returns the next workout to display, or null if none.
  /// If there is already an active workout in progress, routes to it immediately.
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
      return null; // Show nothing while navigating.
    }

    final mesocycleId = appState.currentMesocycleId;
    if (mesocycleId == null) return null;
    _mesocycleId = mesocycleId;
    return db.getNextWorkout(mesocycleId);
  }

  Future<void> _startWorkout(Workout workout) async {
    final mesocycleId = _mesocycleId!;
    await db.advanceRestDays(mesocycleId);
    final next = await db.getNextWorkout(mesocycleId);
    if (next == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreWorkoutCheckinScreen(
          workoutId: next.id,
          workoutName: next.name,
        ),
      ),
    );
    setState(() {
      _nextWorkoutFuture = _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout of Record')),
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
          if (workout == null) {
            return const Center(child: CircularProgressIndicator());
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
