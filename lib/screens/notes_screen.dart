import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../widgets/app_nav_menu.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _controller.text = AppPreferences.getNotes();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    await AppPreferences.setNotes(_controller.text.trim());
    if (mounted) setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        automaticallyImplyLeading: false,
        actions: [
          if (_dirty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
          AppNavMenu(
            current: AppScreen.notes,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
            onNavigateAway: () async {
              if (!_dirty) return true;
              await _save();
              return true;
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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
    );
  }
}
