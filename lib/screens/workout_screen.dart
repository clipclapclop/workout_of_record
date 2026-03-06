import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/workout_data.dart';
import '../db/app_database.dart';
import 'home_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.completedWorkoutId,
    required this.workoutName,
  });

  final int completedWorkoutId;
  final String workoutName;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutData? _data;
  final Map<int, _SetUiState> _setStates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final s in _setStates.values) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await db.getWorkoutData(widget.completedWorkoutId);
    final newStates = <int, _SetUiState>{};

    for (final ex in data.exercises) {
      for (final s in ex.sets) {
        final cs = s.completed;
        final ps = s.planned;
        newStates[cs.id] = _SetUiState(
          reps: cs.reps?.toString() ?? ps?.reps?.toString() ?? '',
          weight: _fmt(cs.weight ?? ps?.weight),
          time: _fmt(cs.time ?? ps?.time),
          isChecked: WorkoutData.setIsDone(s, ex.movement),
        );
      }
    }

    if (mounted) {
      setState(() {
        _data = data;
        // Merge: keep existing controllers (preserves uncheck UI state),
        // only add new ones for newly-seen set IDs.
        for (final entry in newStates.entries) {
          _setStates.putIfAbsent(entry.key, () => entry.value);
        }
        _loading = false;
      });
    }
  }

  String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  bool get _isFinishable =>
      _setStates.isNotEmpty && _setStates.values.every((s) => s.isChecked);

  Future<void> _onToggle(
      int setId, Movement movement, bool checked) async {
    if (checked) {
      final state = _setStates[setId]!;
      await db.saveCompletedSet(
        setId,
        reps: movement.isRequiredReps
            ? int.parse(state.repsCtrl.text.trim())
            : null,
        weight: movement.isRequiredWeight
            ? double.parse(state.weightCtrl.text.trim())
            : null,
        time: movement.isRequiredTime
            ? double.parse(state.timeCtrl.text.trim())
            : null,
      );
    } else {
      await db.clearCompletedSet(setId);
    }
    setState(() => _setStates[setId]!.isChecked = checked);
  }

  Future<void> _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Text('Mark ${widget.workoutName} as complete?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finish')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await db.finishWorkout(widget.completedWorkoutId);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutName),
          automaticallyImplyLeading: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _data!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final exercise in data.exercises)
                  _buildExercise(exercise),
              ],
            ),
          ),
          if (_isFinishable)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _finishWorkout,
                    child: const Text('Finish Workout'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExercise(ExerciseData exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            exercise.movement.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (var i = 0; i < exercise.sets.length; i++)
          _buildSetRow(i + 1, exercise.sets[i], exercise.movement),
      ],
    );
  }

  Widget _buildSetRow(int setNum, SetData setData, Movement movement) {
    final state = _setStates[setData.completed.id]!;
    final canCheck = state.canCheck(movement);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'Set $setNum',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (movement.isRequiredReps) ...[
            const SizedBox(width: 8),
            _inputField(
              state.repsCtrl,
              'Reps',
              isInt: true,
              enabled: !state.isChecked,
            ),
          ],
          if (movement.isRequiredWeight) ...[
            const SizedBox(width: 8),
            _inputField(
              state.weightCtrl,
              'Weight',
              enabled: !state.isChecked,
            ),
          ],
          if (movement.isRequiredTime) ...[
            const SizedBox(width: 8),
            _inputField(
              state.timeCtrl,
              'Time',
              enabled: !state.isChecked,
            ),
          ],
          const SizedBox(width: 8),
          Checkbox(
            value: state.isChecked,
            onChanged: (canCheck || state.isChecked)
                ? (v) => _onToggle(setData.completed.id, movement, v!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    bool isInt = false,
    required bool enabled,
  }) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: isInt
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _SetUiState {
  _SetUiState({
    required this.isChecked,
    String reps = '',
    String weight = '',
    String time = '',
  })  : repsCtrl = TextEditingController(text: reps),
        weightCtrl = TextEditingController(text: weight),
        timeCtrl = TextEditingController(text: time);

  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController timeCtrl;
  bool isChecked;

  bool canCheck(Movement m) {
    if (m.isRequiredReps) {
      final v = int.tryParse(repsCtrl.text.trim());
      if (v == null || v < 1) return false;
    }
    if (m.isRequiredWeight) {
      final v = double.tryParse(weightCtrl.text.trim());
      if (v == null || v <= 0) return false;
    }
    if (m.isRequiredTime) {
      final v = double.tryParse(timeCtrl.text.trim());
      if (v == null || v <= 0) return false;
    }
    return true;
  }

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
    timeCtrl.dispose();
  }
}
