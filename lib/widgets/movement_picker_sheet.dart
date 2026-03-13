import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/tables/enums.dart';
import '../screens/movement_detail_screen.dart';

/// Shows a bottom sheet for picking a movement to add to a template day.
/// [alreadyAdded] prevents duplicate additions (shown greyed out).
Future<void> showMovementPickerSheet({
  required BuildContext context,
  required List<Movement> allMovements,
  required Set<int> alreadyAdded,
  required void Function(Movement) onAdd,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _MovementPickerSheet(
      allMovements: allMovements,
      alreadyAdded: alreadyAdded,
      onAdd: onAdd,
    ),
  );
}

class _MovementPickerSheet extends StatefulWidget {
  const _MovementPickerSheet({
    required this.allMovements,
    required this.alreadyAdded,
    required this.onAdd,
  });

  final List<Movement> allMovements;
  final Set<int> alreadyAdded;
  final void Function(Movement) onAdd;

  @override
  State<_MovementPickerSheet> createState() => _MovementPickerSheetState();
}

class _MovementPickerSheetState extends State<_MovementPickerSheet> {
  final _searchCtrl = TextEditingController();
  MovementCategory _filterCategory = MovementCategory.resistance;
  MuscleGroup? _filterMg;
  String _query = '';
  late List<Movement> _movements;

  @override
  void initState() {
    super.initState();
    _movements = List.of(widget.allMovements);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _createNew(BuildContext ctx) async {
    final Movement? created = await Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const MovementDetailScreen()),
    );
    if (!mounted || created == null) return;
    widget.onAdd(created);
    Navigator.pop(context);
  }

  List<Movement> get _filtered {
    return _movements.where((m) {
      if (m.category != _filterCategory) return false;
      if (_filterMg != null && m.muscleGroup != _filterMg) return false;
      if (_query.isNotEmpty &&
          !m.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  String _mgLabel(MuscleGroup mg) {
    final n = mg.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final allMgs = MuscleGroup.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search exercises…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  DropdownButton<MovementCategory>(
                    value: _filterCategory,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                        value: MovementCategory.resistance,
                        child: Text('Resistance'),
                      ),
                      DropdownMenuItem(
                        value: MovementCategory.cardio,
                        child: Text('Cardio'),
                      ),
                    ],
                    onChanged: (cat) {
                      if (cat == null) return;
                      setState(() {
                        _filterCategory = cat;
                        _filterMg = null;
                      });
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _createNew(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New exercise'),
                  ),
                ],
              ),
            ),
            // Muscle group filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _filterMg == null,
                      onSelected: (_) => setState(() => _filterMg = null),
                    ),
                  ),
                  for (final mg in allMgs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_mgLabel(mg)),
                        selected: _filterMg == mg,
                        onSelected: (_) => setState(() {
                          _filterMg = _filterMg == mg ? null : mg;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),
            // Movement list
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No exercises match.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        final added = widget.alreadyAdded.contains(m.id);
                        return ListTile(
                          title: Text(
                            m.name,
                            style: added
                                ? TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(80),
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            _mgLabel(m.muscleGroup),
                            style: added
                                ? TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(60),
                                  )
                                : null,
                          ),
                          trailing: added
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(80),
                                )
                              : const Icon(Icons.add),
                          onTap: added
                              ? null
                              : () {
                                  widget.onAdd(m);
                                  Navigator.pop(context);
                                },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
