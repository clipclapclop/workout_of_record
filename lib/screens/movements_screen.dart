import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/load_failure_view.dart';
import 'movement_detail_screen.dart';

enum _SortMode { muscleGroup, alphabetical }

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
  final _searchController = TextEditingController();
  String _query = '';
  _SortMode _sortMode = _SortMode.muscleGroup;

  @override
  void initState() {
    super.initState();
    _movementsFuture = db.getMovements();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Movement> _filter(List<Movement> all) {
    if (_query.isEmpty) return all;
    final words = _query.split(RegExp(r'\s+'));
    return all.where((m) {
      final name = m.name.toLowerCase();
      return words.every((w) => name.contains(w));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: _sortMode == _SortMode.muscleGroup
                ? 'Sort alphabetically'
                : 'Sort by muscle group',
            icon: Icon(
              _sortMode == _SortMode.muscleGroup
                  ? Icons.sort_by_alpha
                  : Icons.category_outlined,
            ),
            onPressed: () => setState(() {
              _sortMode = _sortMode == _SortMode.muscleGroup
                  ? _SortMode.alphabetical
                  : _SortMode.muscleGroup;
            }),
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movement>>(
              future: _movementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return LoadFailureView(
                    message: 'Couldn’t load exercises.',
                    onRetry: _reload,
                  );
                }
                final movements = _filter(snapshot.data!);

                if (movements.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }

                if (_sortMode == _SortMode.alphabetical) {
                  final sorted = [...movements]
                    ..sort((a, b) => a.name.compareTo(b.name));
                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => _MovementTile(
                      movement: sorted[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovementDetailScreen(
                              movement: sorted[i],
                              activeWorkoutId: widget.activeWorkoutId,
                              activeWorkoutName: widget.activeWorkoutName,
                            ),
                          ),
                        );
                        _reload();
                      },
                    ),
                  );
                }

                // Muscle-group mode
                final groups = <MuscleGroup, List<Movement>>{};
                for (final m in movements) {
                  groups.putIfAbsent(m.muscleGroup, () => []).add(m);
                }
                final sortedGroups = groups.keys.toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                return ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: sortedGroups.fold<int>(
                      0, (sum, mg) => sum + 1 + groups[mg]!.length),
                  itemBuilder: (context, index) {
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
          ),
        ],
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
