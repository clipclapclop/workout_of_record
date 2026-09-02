import 'package:flutter/material.dart';

class EmptyWorkoutView extends StatelessWidget {
  const EmptyWorkoutView({
    super.key,
    required this.onAddExercise,
    required this.onFinishWorkout,
  });

  final VoidCallback onAddExercise;
  final VoidCallback onFinishWorkout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an exercise, or finish this workout empty.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onFinishWorkout,
            child: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }
}
