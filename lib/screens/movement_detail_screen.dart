import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';

class MovementDetailScreen extends StatefulWidget {
  const MovementDetailScreen({
    super.key,
    this.movement,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  /// Null when creating a new exercise.
  final Movement? movement;
  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<MovementDetailScreen> createState() => _MovementDetailScreenState();
}

class _MovementDetailScreenState extends State<MovementDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _subMuscleCtrl;
  late final TextEditingController _note1Ctrl;
  late final TextEditingController _note2Ctrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _minWeightCtrl;
  late final TextEditingController _weightDeltaCtrl;

  late MuscleGroup _muscleGroup;
  late bool _isRequiredReps;
  late bool _isRequiredWeight;
  late bool _isRequiredTime;

  @override
  void initState() {
    super.initState();
    final m = widget.movement;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _subMuscleCtrl = TextEditingController(text: m?.subMuscleGroup ?? '');
    _note1Ctrl = TextEditingController(text: m?.note1 ?? '');
    _note2Ctrl = TextEditingController(text: m?.note2 ?? '');
    _linkCtrl = TextEditingController(text: m?.link ?? '');
    _minWeightCtrl = TextEditingController(
        text: m?.minWeight != null ? _fmt(m!.minWeight!) : '');
    _weightDeltaCtrl = TextEditingController(
        text: m?.weightDelta != null ? _fmt(m!.weightDelta!) : '');
    _muscleGroup = m?.muscleGroup ?? MuscleGroup.values.first;
    _isRequiredReps = m?.isRequiredReps ?? true;
    _isRequiredWeight = m?.isRequiredWeight ?? true;
    _isRequiredTime = m?.isRequiredTime ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subMuscleCtrl.dispose();
    _note1Ctrl.dispose();
    _note2Ctrl.dispose();
    _linkCtrl.dispose();
    _minWeightCtrl.dispose();
    _weightDeltaCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final companion = MovementsCompanion(
      name: Value(_nameCtrl.text.trim()),
      muscleGroup: Value(_muscleGroup),
      subMuscleGroup: Value(
          _subMuscleCtrl.text.trim().isEmpty ? null : _subMuscleCtrl.text.trim()),
      note1: Value(_note1Ctrl.text.trim().isEmpty ? null : _note1Ctrl.text.trim()),
      note2: Value(_note2Ctrl.text.trim().isEmpty ? null : _note2Ctrl.text.trim()),
      link: Value(_linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim()),
      minWeight: Value(double.tryParse(_minWeightCtrl.text.trim())),
      weightDelta: Value(double.tryParse(_weightDeltaCtrl.text.trim())),
      isRequiredReps: Value(_isRequiredReps),
      isRequiredWeight: Value(_isRequiredWeight),
      isRequiredTime: Value(_isRequiredTime),
    );
    if (widget.movement != null) {
      await db.updateMovement(companion.copyWith(id: Value(widget.movement!.id)));
      if (mounted) Navigator.pop(context);
    } else {
      final created = await db.createMovement(companion);
      if (mounted) Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movement?.name ?? 'New Exercise'),
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          AppNavMenu(
            current: AppScreen.exercises,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MuscleGroup>(
              key: ValueKey(_muscleGroup),
              initialValue: _muscleGroup,
              decoration: const InputDecoration(labelText: 'Muscle Group'),
              items: (MuscleGroup.values.toList()
                    ..sort((a, b) => a.name.compareTo(b.name)))
                  .map((mg) {
                final label = mg.name[0].toUpperCase() + mg.name.substring(1);
                return DropdownMenuItem(value: mg, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _muscleGroup = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subMuscleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sub-muscle Group (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const Text('Required inputs'),
            SwitchListTile(
              title: const Text('Reps'),
              value: _isRequiredReps,
              onChanged: (v) => setState(() => _isRequiredReps = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Weight'),
              value: _isRequiredWeight,
              onChanged: (v) => setState(() => _isRequiredWeight = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Time'),
              value: _isRequiredTime,
              onChanged: (v) => setState(() => _isRequiredTime = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minWeightCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Min Weight (optional)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty &&
                          double.tryParse(v.trim()) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightDeltaCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Weight Step (optional)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty &&
                          double.tryParse(v.trim()) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note1Ctrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note2Ctrl,
              decoration:
                  const InputDecoration(labelText: 'Note 2 (optional)'),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkCtrl,
              decoration: const InputDecoration(labelText: 'Link (optional)'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
