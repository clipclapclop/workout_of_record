import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/template_data.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/movement_picker_sheet.dart';

/// In-memory representation of one day while the user is building the template.
class _DayDraft {
  _DayDraft({required this.name, required this.isRestDay, List<Movement>? exercises})
      : exercises = exercises ?? [];

  String name;
  bool isRestDay;
  List<Movement> exercises;
}

class MesoTemplateBuilderScreen extends StatefulWidget {
  const MesoTemplateBuilderScreen({
    super.key,
    /// Non-null when editing an existing template or copying one.
    this.existing,
    /// true  → Save calls createMesoTemplate (new row).
    /// false → Save calls updateMesoTemplate (existing row).
    required this.isNew,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final MesoTemplateData? existing;
  final bool isNew;
  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<MesoTemplateBuilderScreen> createState() =>
      _MesoTemplateBuilderScreenState();
}

class _MesoTemplateBuilderScreenState extends State<MesoTemplateBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final List<_DayDraft> _days;
  late TabController _tabCtrl;

  // Cached movement list for the picker.
  List<Movement>? _allMovements;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _nameCtrl = TextEditingController(
      text: existing?.template.name ?? '',
    );

    _days = existing != null
        ? existing.days
            .map((d) => _DayDraft(
                  name: d.template.name,
                  isRestDay: d.template.isRestDay,
                  exercises: List<Movement>.from(d.movements),
                ))
            .toList()
        : [_DayDraft(name: '', isRestDay: false)];

    _tabCtrl = TabController(length: _days.length + 1, vsync: this);
    _loadMovements();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    final movs = await db.getMovements();
    if (mounted) setState(() => _allMovements = movs);
  }

  // ── Tab controller helpers ─────────────────────────────────────────────────

  void _rebuildTabs({int? jumpTo}) {
    final oldIndex = _tabCtrl.index;
    _tabCtrl.dispose();
    _tabCtrl = TabController(length: _days.length + 1, vsync: this);
    final target = jumpTo ?? oldIndex.clamp(0, _days.length - 1);
    // Schedule after build so the new controller is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && target < _days.length) {
        _tabCtrl.animateTo(target);
      }
    });
    setState(() {});
  }

  // ── Day management ─────────────────────────────────────────────────────────

  Future<void> _addDay() async {
    final result = await _showDayNameDialog();
    if (result == null) return;
    _days.add(_DayDraft(name: result.name, isRestDay: result.isRestDay));
    _rebuildTabs(jumpTo: _days.length - 1);
  }

  Future<void> _renameDay(int index) async {
    final day = _days[index];
    final result = await _showDayNameDialog(
      initialName: day.name,
      initialIsRestDay: day.isRestDay,
    );
    if (result == null) return;
    setState(() {
      day.name = result.name;
      day.isRestDay = result.isRestDay;
    });
  }

  void _deleteDay(int index) {
    if (_days.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A template must have at least one day.')),
      );
      return;
    }
    setState(() => _days.removeAt(index));
    _rebuildTabs(jumpTo: (index - 1).clamp(0, _days.length - 1));
  }

  // ── Exercise management ────────────────────────────────────────────────────

  Future<void> _addExercise(int dayIndex) async {
    final movs = _allMovements;
    if (movs == null || !mounted) return;
    final day = _days[dayIndex];
    await showMovementPickerSheet(
      context: context,
      allMovements: movs,
      alreadyAdded: {for (final e in day.exercises) e.id},
      onAdd: (m) => setState(() => day.exercises.add(m)),
    );
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() => _days[dayIndex].exercises.removeAt(exIndex));
  }

  void _reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      final day = _days[dayIndex];
      if (newIndex > oldIndex) newIndex--;
      final item = day.exercises.removeAt(oldIndex);
      day.exercises.insert(newIndex, item);
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name.')),
      );
      return;
    }
    if (_days.any((d) => d.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All days must have a name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final specs = _days
          .map((d) => WorkoutDaySpec(
                name: d.name.trim(),
                isRestDay: d.isRestDay,
                movementIds: d.exercises.map((e) => e.id).toList(),
              ))
          .toList();

      if (widget.isNew) {
        await db.createMesoTemplate(name, specs);
      } else {
        await db.updateMesoTemplate(widget.existing!.template.id, name, specs);
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Day name dialog ────────────────────────────────────────────────────────

  Future<_DayNameResult?> _showDayNameDialog({
    String initialName = '',
    bool initialIsRestDay = false,
  }) {
    return showDialog<_DayNameResult>(
      context: context,
      builder: (ctx) => _DayNameDialog(
        initialName: initialName,
        initialIsRestDay: initialIsRestDay,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Template name',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        automaticallyImplyLeading: true,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          AppNavMenu(
            current: AppScreen.mesoTemplates,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
          ),
        ],
        bottom: _days.isEmpty
            ? null
            : TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final day in _days)
                    _DayTab(
                      label: day.name.isEmpty ? '—' : day.name,
                      isRestDay: day.isRestDay,
                      onOptions: () => _showDayTabOptions(
                        _days.indexOf(day),
                      ),
                    ),
                  // "+" tab to add a day
                  Tab(
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add day',
                      onPressed: _addDay,
                    ),
                  ),
                ],
              ),
      ),
      body: _allMovements == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              // Last "tab" for the + button is never shown as a body.
              children: [
                for (var i = 0; i < _days.length; i++) _buildDayTab(i),
                // Placeholder body for the + tab (never actually shown).
                const SizedBox.shrink(),
              ],
            ),
    );
  }

  Widget _buildDayTab(int dayIndex) {
    final day = _days[dayIndex];

    if (day.isRestDay) {
      return Center(
        child: Text(
          'Rest Day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: day.exercises.isEmpty
              ? Center(
                  child: Text(
                    'No exercises yet.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: day.exercises.length,
                  onReorder: (old, newIdx) =>
                      _reorderExercises(dayIndex, old, newIdx),
                  itemBuilder: (context, i) {
                    final m = day.exercises[i];
                    final showHeader = i == 0 ||
                        day.exercises[i - 1].muscleGroup != m.muscleGroup;
                    final mgLabel = m.muscleGroup.name[0].toUpperCase() +
                        m.muscleGroup.name.substring(1);
                    return Column(
                      key: ValueKey(m.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                            child: Text(
                              mgLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ),
                        ListTile(
                          leading: ReorderableDragStartListener(
                            index: i,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(m.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remove',
                            onPressed: () => _removeExercise(dayIndex, i),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addExercise(dayIndex),
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
          ),
        ),
      ],
    );
  }

  void _showDayTabOptions(int index) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename / change type'),
              onTap: () {
                Navigator.pop(ctx);
                _renameDay(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete day'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteDay(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day tab widget ─────────────────────────────────────────────────────────

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.label,
    required this.isRestDay,
    required this.onOptions,
  });

  final String label;
  final bool isRestDay;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRestDay)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.hotel,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140)),
            ),
          Text(label),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onOptions,
            child: Icon(
              Icons.more_vert,
              size: 16,
              color:
                  Theme.of(context).colorScheme.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day name dialog ────────────────────────────────────────────────────────

class _DayNameResult {
  const _DayNameResult({required this.name, required this.isRestDay});
  final String name;
  final bool isRestDay;
}

class _DayNameDialog extends StatefulWidget {
  const _DayNameDialog({
    required this.initialName,
    required this.initialIsRestDay,
  });

  final String initialName;
  final bool initialIsRestDay;

  @override
  State<_DayNameDialog> createState() => _DayNameDialogState();
}

class _DayNameDialogState extends State<_DayNameDialog> {
  late final TextEditingController _ctrl;
  late bool _isRestDay;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _isRestDay = widget.initialIsRestDay;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Day'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Rest day'),
              const Spacer(),
              Switch(
                value: _isRestDay,
                onChanged: (v) => setState(() => _isRestDay = v),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, _DayNameResult(name: name, isRestDay: _isRestDay));
  }
}
