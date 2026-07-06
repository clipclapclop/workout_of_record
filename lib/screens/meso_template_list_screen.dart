import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/template_data.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/meso_template_card.dart';
import 'meso_template_builder_screen.dart';

class MesoTemplateListScreen extends StatefulWidget {
  const MesoTemplateListScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<MesoTemplateListScreen> createState() => _MesoTemplateListScreenState();
}

class _MesoTemplateListScreenState extends State<MesoTemplateListScreen> {
  late Future<List<MesoTemplateWithHistory>> _templatesFuture;
  MesoTemplateSort _sort = MesoTemplateSort.lastUsed;

  @override
  void initState() {
    super.initState();
    _templatesFuture = db.getMesoTemplatesWithHistory();
  }

  void _reload() {
    setState(() {
      _templatesFuture = db.getMesoTemplatesWithHistory();
    });
  }

  Future<void> _openBuilder({MesoTemplateData? existing, bool isNew = true}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesoTemplateBuilderScreen(
          existing: existing,
          isNew: isNew,
          activeWorkoutId: widget.activeWorkoutId,
          activeWorkoutName: widget.activeWorkoutName,
        ),
      ),
    );
    _reload();
  }

  Future<void> _onEdit(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    await _openBuilder(existing: data, isNew: false);
  }

  Future<void> _onCopy(MesoTemplate t) async {
    final data = await db.getMesoTemplateData(t.id);
    if (!mounted) return;
    // Open builder with existing data but treated as new (different name pre-filled).
    await _openBuilder(
      existing: MesoTemplateData(
        template: MesoTemplate(id: -1, name: 'Copy of ${data.template.name}', createdAt: DateTime.now()),
        days: data.days,
      ),
      isNew: true,
    );
  }

  Future<void> _onDelete(MesoTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${t.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await db.deleteMesoTemplate(t.id);
      _reload();
    } on TemplateInUseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This template is used by the active mesocycle and cannot be deleted.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meso Templates'),
        automaticallyImplyLeading: true,
        actions: [
          MesoTemplateSortButton(
            value: _sort,
            onChanged: (value) => setState(() => _sort = value),
          ),
          AppNavMenu(
            current: AppScreen.mesoTemplates,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBuilder(),
        tooltip: 'New template',
        child: const Icon(Icons.add),
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
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No templates yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openBuilder(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create template'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            itemCount: templates.length,
            itemBuilder: (context, i) {
              final history = templates[i];
              final template = history.template;
              return MesoTemplateCard(
                history: history,
                onTap: () => _onEdit(template),
                onEdit: () => _onEdit(template),
                onCopy: () => _onCopy(template),
                onDelete: () => _onDelete(template),
              );
            },
          );
        },
      ),
    );
  }
}
