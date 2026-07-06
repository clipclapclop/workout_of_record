import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/template_data.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/meso_template_card.dart';
import 'home_screen.dart';
import '../widgets/past_meso_picker_sheet.dart';
import 'meso_template_builder_screen.dart';
import 'past_week_review_screen.dart';

class MesocycleSetupScreen extends StatefulWidget {
  const MesocycleSetupScreen({super.key});

  @override
  State<MesocycleSetupScreen> createState() => _MesocycleSetupScreenState();
}

class _MesocycleSetupScreenState extends State<MesocycleSetupScreen> {
  late Future<List<MesoTemplateWithHistory>> _templatesFuture;
  late Future<bool> _hasPastWeeksFuture;
  MesoTemplate? _selected;
  final _nameController = TextEditingController();
  int _totalWeeks = 4;
  bool _saving = false;
  MesoTemplateSort _sort = MesoTemplateSort.lastUsed;

  @override
  void initState() {
    super.initState();
    _templatesFuture = db.getMesoTemplatesWithHistory();
    _hasPastWeeksFuture = db
        .getMesocyclesWithCompletedWeeks()
        .then((summaries) => summaries.isNotEmpty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reload({int? selectTemplateId}) async {
    setState(() {
      _templatesFuture = db.getMesoTemplatesWithHistory();
      _selected = null;
      _nameController.clear();
    });
    if (selectTemplateId == null) return;
    final selected = (await db.getMesoTemplateData(selectTemplateId)).template;
    if (!mounted) return;
    setState(() {
      _selected = selected;
      _nameController.text = selected.name;
    });
  }

  void _selectTemplate(MesoTemplate template) {
    final previous = _selected;
    final useTemplateName = _nameController.text.isEmpty ||
        (previous != null && _nameController.text == previous.name);
    setState(() {
      _selected = template;
      if (useTemplateName) _nameController.text = template.name;
    });
  }

  Future<void> _createTemplate() async {
    final templateId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const MesoTemplateBuilderScreen(isNew: true)),
    );
    await _reload(selectTemplateId: templateId);
  }

  Future<void> _onEdit(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => MesoTemplateBuilderScreen(existing: data, isNew: false),
      ),
    );
    await _reload(selectTemplateId: _selected?.id);
  }

  Future<void> _onCopy(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    final templateId = await Navigator.push<int>(
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
    await _reload(selectTemplateId: templateId);
  }

  Future<void> _onCopyFromPastMeso() async {
    final data = await showPastMesoPickerSheet(context);
    if (data == null || !mounted) return;
    final templateId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => PastWeekReviewScreen(data: data),
      ),
    );
    await _reload(selectTemplateId: templateId);
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
    final mesocycleId = await db.createMesocycle(template.id, name, _totalWeeks);
    await AppPreferences.setCurrentMesocycleId(mesocycleId);
    await AppPreferences.setCurrentCompletedWorkoutId(null);
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
        title: const Text('Mesocycle Setup'),
        automaticallyImplyLeading: false,
        actions: [
          MesoTemplateSortButton(
            value: _sort,
            onChanged: (value) => setState(() => _sort = value),
          ),
          AppNavMenu(current: AppScreen.workout),
        ],
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

          final templates = sortMesoTemplates(snapshot.data!, _sort);
          final selectedTemplate = _selected;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: selectedTemplate == null
                      ? EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom)
                      : const EdgeInsets.all(16),
                  children: [
                    Text('Choose a Template',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Select a saved plan, create one, or review a completed week from a past mesocycle.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (templates.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No templates yet. Create one below.'),
                      ),
                    ...templates.map((th) => MesoTemplateCard(
                          history: th,
                          isSelected: _selected?.id == th.template.id,
                          showSelection: true,
                          onTap: () => _selectTemplate(th.template),
                          onEdit: () => _onEdit(th.template),
                          onCopy: () => _onCopy(th.template),
                        )),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _createTemplate,
                      icon: const Icon(Icons.add),
                      label: const Text('New Template'),
                    ),
                    FutureBuilder<bool>(
                      future: _hasPastWeeksFuture,
                      builder: (context, snapshot) => snapshot.data == true
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                onPressed: _onCopyFromPastMeso,
                                icon: const Icon(Icons.history),
                                label: const Text(
                                  'Review Past Mesocycle Week',
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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
                          labelText: 'Mesocycle name',
                          helperText: 'Names this run; the selected template is unchanged.',
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
