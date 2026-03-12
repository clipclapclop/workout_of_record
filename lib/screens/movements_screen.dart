import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'movement_detail_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  late Future<List<Movement>> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _movementsFuture = db.getMovements();
  }

  void _reload() {
    setState(() {
      _movementsFuture = db.getMovements();
    });
  }

  String _mgLabel(MuscleGroup mg) {
    final name = mg.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.exercises,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovementDetailScreen(
                activeWorkoutId: widget.activeWorkoutId,
                activeWorkoutName: widget.activeWorkoutName,
              ),
            ),
          );
          _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Movement>>(
        future: _movementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final allMovements = snapshot.data!;

          // Group by muscle group (DB already sorted by muscleGroup then name).
          final groups = <MuscleGroup, List<Movement>>{};
          for (final m in allMovements) {
            groups.putIfAbsent(m.muscleGroup, () => []).add(m);
          }
          final sortedGroups = groups.keys.toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return ListView.builder(
            itemCount: sortedGroups.fold<int>(0, (sum, mg) => sum + 1 + groups[mg]!.length),
            itemBuilder: (context, index) {
              // Map flat index → (group header or item).
              var remaining = index;
              for (final mg in sortedGroups) {
                if (remaining == 0) {
                  return _GroupHeader(label: _mgLabel(mg));
                }
                remaining--;
                final items = groups[mg]!;
                if (remaining < items.length) {
                  return _MovementTile(
                    movement: items[remaining],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovementDetailScreen(
                            movement: items[remaining],
                            activeWorkoutId: widget.activeWorkoutId,
                            activeWorkoutName: widget.activeWorkoutName,
                          ),
                        ),
                      );
                      _reload();
                    },
                  );
                }
                remaining -= items.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.onTap});
  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flags = [
      if (movement.isRequiredReps) 'Reps',
      if (movement.isRequiredWeight) 'Weight',
      if (movement.isRequiredTime) 'Time',
    ].join(' · ');

    return ListTile(
      title: Text(movement.name),
      subtitle: flags.isNotEmpty ? Text(flags) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
