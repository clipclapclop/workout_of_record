import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/template_data.dart';
import '../widgets/app_nav_menu.dart';
import 'home_screen.dart';
import 'meso_template_builder_screen.dart';

class MesocycleSetupScreen extends StatefulWidget {
  const MesocycleSetupScreen({super.key});

  @override
  State<MesocycleSetupScreen> createState() => _MesocycleSetupScreenState();
}

class _MesocycleSetupScreenState extends State<MesocycleSetupScreen> {
  late Future<List<MesoTemplateWithHistory>> _templatesFuture;
  MesoTemplate? _selected;
  final _nameController = TextEditingController();
  int _totalWeeks = 4;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _templatesFuture = db.getMesoTemplatesWithHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _templatesFuture = db.getMesoTemplatesWithHistory();
      _selected = null;
      _nameController.clear();
    });
  }

  Future<void> _createTemplate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MesoTemplateBuilderScreen(isNew: true)),
    );
    _reload();
  }

  Future<void> _onEdit(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesoTemplateBuilderScreen(existing: data, isNew: false),
      ),
    );
    _reload();
  }

  Future<void> _onCopy(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesoTemplateBuilderScreen(
          existing: MesoTemplateData(
            template: MesoTemplate(
                id: -1,
                name: 'Copy of ${data.template.name}',
                createdAt: DateTime.now()),
            days: data.days,
          ),
          isNew: true,
        ),
      ),
    );
    _reload();
  }

  Future<void> _startMesocycle() async {
    final template = _selected;
    if (template == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this mesocycle.')),
      );
      return;
    }

    setState(() => _saving = true);
    await db.createMesocycle(template.id, name, _totalWeeks);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Mesocycle'),
        automaticallyImplyLeading: false,
        actions: [AppNavMenu(current: AppScreen.workout)],
      ),
      body: FutureBuilder<List<MesoTemplateWithHistory>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final templates = snapshot.data!;
          final selectedTemplate = _selected;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Choose a Template',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (templates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No templates yet. Create one below.'),
                      ),
                    ...templates.map((th) => _TemplateCard(
                          history: th,
                          isSelected: _selected?.id == th.template.id,
                          onTap: () => setState(() {
                            _selected = th.template;
                            if (_nameController.text.isEmpty) {
                              _nameController.text = th.template.name;
                            }
                          }),
                          onEdit: () => _onEdit(th.template),
                          onCopy: () => _onCopy(th.template),
                        )),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _createTemplate,
                      icon: const Icon(Icons.add),
                      label: const Text('New Template'),
                    ),
                    if (selectedTemplate != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text('Mesocycle Details',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _WeekCountPicker(
                        value: _totalWeeks,
                        onChanged: (v) => setState(() => _totalWeeks = v),
                      ),
                    ],
                  ],
                ),
              ),
              if (selectedTemplate != null)
                _BottomBar(saving: _saving, onStart: _startMesocycle),
            ],
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ── Template card ─────────────────────────────────────────────────────────────

enum _CardAction { edit, copy }

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.history,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onCopy,
  });

  final MesoTemplateWithHistory history;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final template = history.template;
    final completed =
        history.pastMesos.where((m) => m.completedAt != null).toList();
    final lastCompleted =
        completed.isNotEmpty ? completed.first.completedAt : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(template.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (lastCompleted != null)
                      Text(
                        'Last completed ${_formatDate(lastCompleted)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary),
              PopupMenuButton<_CardAction>(
                onSelected: (action) {
                  switch (action) {
                    case _CardAction.edit:
                      onEdit();
                    case _CardAction.copy:
                      onCopy();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _CardAction.edit, child: Text('Edit')),
                  PopupMenuItem(value: _CardAction.copy, child: Text('Copy')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Week count picker ─────────────────────────────────────────────────────────

class _WeekCountPicker extends StatelessWidget {
  const _WeekCountPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Weeks',
                  style: Theme.of(context).textTheme.labelLarge),
              Text('Last week is always a deload',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 2 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < 16 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.saving, required this.onStart});

  final bool saving;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : onStart,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Mesocycle'),
          ),
        ),
      ),
    );
  }
}
