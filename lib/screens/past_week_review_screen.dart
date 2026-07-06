import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/template_data.dart';
import 'meso_template_builder_screen.dart';

class PastWeekReviewScreen extends StatefulWidget {
  const PastWeekReviewScreen({super.key, required this.data});

  final PastWeekTemplateData data;

  @override
  State<PastWeekReviewScreen> createState() => _PastWeekReviewScreenState();
}

class _PastWeekReviewScreenState extends State<PastWeekReviewScreen> {
  bool _saving = false;

  List<WorkoutDaySpec> get _weekSpecs =>
      workoutDaySpecsFromData(widget.data.weekData);

  Future<void> _useWeek() async {
    final source = widget.data.associatedTemplate.template;
    setState(() => _saving = true);
    final matches = await db.mesoTemplateMatches(source.id, _weekSpecs);
    if (!mounted) return;
    setState(() => _saving = false);
    if (matches) {
      Navigator.pop(context, source.id);
      return;
    }

    final action = await showDialog<_MismatchAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('This week changed'),
        content: Text(
          'The completed week no longer matches the saved template '
          '"${source.name}". You can update that template to this week or '
          'save the week as a separate template.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _MismatchAction.updateExisting),
            child: const Text('Update Existing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _MismatchAction.saveAsNew),
            child: const Text('Save as New'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _MismatchAction.updateExisting:
        setState(() => _saving = true);
        await db.updateMesoTemplate(source.id, source.name, _weekSpecs);
        if (mounted) Navigator.pop(context, source.id);
        return;
      case _MismatchAction.saveAsNew:
        await _saveAsNew();
        return;
    }
  }

  Future<void> _saveAsNew() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _NewTemplateNameDialog(suggestedName: widget.data.suggestedName),
    );
    if (name == null || !mounted) return;
    setState(() => _saving = true);
    final templateId = await db.createMesoTemplate(name, _weekSpecs);
    if (mounted) Navigator.pop(context, templateId);
  }

  Future<void> _editWeek() async {
    final source = widget.data.associatedTemplate.template;
    final structureMatches = await db.mesoTemplateMatches(
      source.id,
      _weekSpecs,
    );
    if (!mounted) return;
    final initial = MesoTemplateData(
      template: MesoTemplate(
        id: -1,
        name: structureMatches ? source.name : widget.data.suggestedName,
        createdAt: DateTime.now(),
      ),
      days: widget.data.weekData.days,
    );
    final templateId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => MesoTemplateBuilderScreen(
          existing: initial,
          isNew: true,
          pastWeekSourceTemplateId: source.id,
          pastWeekSourceTemplateName: source.name,
        ),
      ),
    );
    if (templateId != null && mounted) Navigator.pop(context, templateId);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final days = data.weekData.days;
    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Review Week ${data.week.weekNumber}'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final day in days)
                Tab(
                  icon: day.template.isRestDay
                      ? const Icon(Icons.hotel, size: 16)
                      : null,
                  text: day.template.name,
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Text(
                'This is week ${data.week.weekNumber} from "${data.mesocycle.name}". '
                'Use Week compares it with the saved template '
                '"${data.associatedTemplate.template.name}". Edit Week lets '
                'you change it before choosing a template.',
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [for (final day in days) _ReviewDay(day: day)],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _editWeek,
                    child: const Text('Edit Week'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _useWeek,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Use Week'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewDay extends StatelessWidget {
  const _ReviewDay({required this.day});

  final WorkoutDayData day;

  @override
  Widget build(BuildContext context) {
    if (day.template.isRestDay) {
      return const Center(child: Text('Rest Day'));
    }
    if (day.exercises.isEmpty) {
      return const Center(child: Text('No persistent exercises.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: day.exercises.length,
      itemBuilder: (context, index) {
        final exercise = day.exercises[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(exercise.movement.name),
          subtitle: Text(
            exercise.autoProgress ? 'Auto-progress on' : 'Auto-progress off',
          ),
        );
      },
    );
  }
}

class _NewTemplateNameDialog extends StatefulWidget {
  const _NewTemplateNameDialog({required this.suggestedName});

  final String suggestedName;

  @override
  State<_NewTemplateNameDialog> createState() => _NewTemplateNameDialogState();
}

class _NewTemplateNameDialogState extends State<_NewTemplateNameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a template name.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    if (await db.mesoTemplateNameExists(name)) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = 'A template with this name already exists.';
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as New Template'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Template name',
          errorText: _error,
        ),
        onSubmitted: (_) {
          if (!_checking) _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

enum _MismatchAction { updateExisting, saveAsNew }
