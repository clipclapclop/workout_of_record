import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/unsaved_changes_dialog.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, this.activeWorkoutId, this.activeWorkoutName});

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();
  late String _savedText;

  bool get _hasUnsavedChanges => _controller.text.trim() != _savedText;

  @override
  void initState() {
    super.initState();
    _savedText = AppPreferences.getNotes();
    _controller.text = _savedText;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  Future<bool> _save() async {
    final text = _controller.text.trim();
    try {
      await AppPreferences.setNotes(text);
      if (mounted) setState(() => _savedText = text);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Couldn’t save notes.')));
      }
      return false;
    }
  }

  Future<bool> _confirmNavigateAway() async {
    if (!_hasUnsavedChanges) return true;
    final action = await showUnsavedChangesDialog(context);
    return switch (action) {
      UnsavedChangesAction.keepEditing => false,
      UnsavedChangesAction.discard => true,
      UnsavedChangesAction.save => _save(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmNavigateAway();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes'),
          automaticallyImplyLeading: false,
          actions: [
            if (_hasUnsavedChanges)
              IconButton(icon: const Icon(Icons.save), onPressed: _save),
            AppNavMenu(
              current: AppScreen.notes,
              activeWorkoutId: widget.activeWorkoutId,
              activeWorkoutName: widget.activeWorkoutName,
              onNavigateAway: _confirmNavigateAway,
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Jot down anything you want to remember...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
