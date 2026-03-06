import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
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
  // keyed by completedExercise.id
  final Map<int, bool> _postExDone = {};
  // keyed by MuscleGroup
  final Map<MuscleGroup, bool> _postMgDone = {};
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

    final newSetStates = <int, _SetUiState>{};
    for (final ex in data.exercises) {
      for (final s in ex.sets) {
        final cs = s.completed;
        final ps = s.planned;
        newSetStates[cs.id] = _SetUiState(
          reps: cs.reps?.toString() ?? ps?.reps?.toString() ?? '',
          weight: _fmt(cs.weight ?? ps?.weight),
          time: _fmt(cs.time ?? ps?.time),
          isChecked: WorkoutData.setIsDone(s, ex.movement),
        );
      }
      _postExDone.putIfAbsent(
          ex.completed.id, () => ex.postExerciseCheckin != null);
      _postMgDone.putIfAbsent(ex.movement.muscleGroup, () => false);
    }
    for (final mgCheckin in data.postMuscleGroupCheckins) {
      _postMgDone[mgCheckin.muscleGroup] = true;
    }

    if (mounted) {
      setState(() {
        _data = data;
        for (final entry in newSetStates.entries) {
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

  bool get _isFinishable {
    if (_data == null || _setStates.isEmpty) return false;
    for (final ex in _data!.exercises) {
      if (!ex.sets.every(
          (s) => _setStates[s.completed.id]?.isChecked ?? false)) {
        return false;
      }
      if (_postExDone[ex.completed.id] != true) return false;
    }
    final muscleGroups =
        _data!.exercises.map((e) => e.movement.muscleGroup).toSet();
    return muscleGroups.every((mg) => _postMgDone[mg] == true);
  }

  /// Index of the last exercise for each muscle group, by position in the list.
  Map<MuscleGroup, int> _lastExIndexForMg() {
    final result = <MuscleGroup, int>{};
    final exercises = _data!.exercises;
    for (var i = 0; i < exercises.length; i++) {
      result[exercises[i].movement.muscleGroup] = i;
    }
    return result;
  }

  Future<void> _onToggle(
      int setId, Movement movement, bool checked, ExerciseData exercise) async {
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

    // After checking, see if the exercise's last set was just completed.
    if (checked && _postExDone[exercise.completed.id] != true) {
      final allSetsDone = exercise.sets
          .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
      if (allSetsDone && mounted) {
        await _showPostExerciseSheet(exercise);
      }
    }
  }

  Future<void> _showPostExerciseSheet(ExerciseData exercise) async {
    var jointPain = Soreness.none;
    var submitted = false;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.movement.name,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Any joint pain?'),
              const SizedBox(height: 12),
              SegmentedButton<Soreness>(
                segments: const [
                  ButtonSegment(value: Soreness.none, label: Text('None')),
                  ButtonSegment(
                      value: Soreness.aLittle, label: Text('A Little')),
                  ButtonSegment(value: Soreness.some, label: Text('Some')),
                  ButtonSegment(value: Soreness.lots, label: Text('Lots')),
                ],
                selected: {jointPain},
                onSelectionChanged: (v) =>
                    setSheet(() => jointPain = v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      await db.savePostExerciseCheckin(
                        PostExerciseCheckinsCompanion.insert(
                          completedExerciseId: exercise.completed.id,
                          jointPain: jointPain,
                        ),
                      );
                      submitted = true;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!submitted || !mounted) return;

    setState(() => _postExDone[exercise.completed.id] = true);

    // If all exercises for this muscle group now have check-ins, show MG sheet.
    final mg = exercise.movement.muscleGroup;
    final allMgDone = _data!.exercises
        .where((e) => e.movement.muscleGroup == mg)
        .every((e) => _postExDone[e.completed.id] == true);
    if (allMgDone && _postMgDone[mg] != true && mounted) {
      await _showPostMuscleGroupSheet(mg);
    }
  }

  Future<void> _showPostMuscleGroupSheet(MuscleGroup muscleGroup) async {
    var effort = Effort.hard;
    var volume = Volume.good;
    var submitted = false;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_mgLabel(muscleGroup),
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              const Text('How hard did you work?'),
              const SizedBox(height: 8),
              SegmentedButton<Effort>(
                segments: const [
                  ButtonSegment(
                      value: Effort.tooEasy, label: Text('Too Easy')),
                  ButtonSegment(value: Effort.easy, label: Text('Easy')),
                  ButtonSegment(value: Effort.hard, label: Text('Hard')),
                  ButtonSegment(
                      value: Effort.tooHard, label: Text('Too Hard')),
                ],
                selected: {effort},
                onSelectionChanged: (v) => setSheet(() => effort = v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              const Text('How was the volume?'),
              const SizedBox(height: 8),
              SegmentedButton<Volume>(
                segments: const [
                  ButtonSegment(
                      value: Volume.tooLittle, label: Text('Too Little')),
                  ButtonSegment(value: Volume.good, label: Text('Good')),
                  ButtonSegment(value: Volume.aLot, label: Text('A Lot')),
                  ButtonSegment(
                      value: Volume.wayTooMuch, label: Text('Way Too Much')),
                ],
                selected: {volume},
                onSelectionChanged: (v) => setSheet(() => volume = v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      await db.savePostMuscleGroupCheckin(
                        PostMuscleGroupCheckinsCompanion.insert(
                          completedWorkoutId: widget.completedWorkoutId,
                          muscleGroup: muscleGroup,
                          effortLevel: effort,
                          volumeLevel: volume,
                        ),
                      );
                      submitted = true;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!submitted || !mounted) return;
    setState(() => _postMgDone[muscleGroup] = true);
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

  String _mgLabel(MuscleGroup mg) {
    final name = mg.name;
    return name[0].toUpperCase() + name.substring(1);
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
    final lastExIndexForMg = _lastExIndexForMg();

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
                for (var i = 0; i < data.exercises.length; i++)
                  _buildExercise(data.exercises[i], i, lastExIndexForMg),
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

  Widget _buildExercise(
      ExerciseData exercise, int index, Map<MuscleGroup, int> lastExIndexForMg) {
    final allSetsDone = exercise.sets
        .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
    final postExDone = _postExDone[exercise.completed.id] == true;
    final showPostExReopen = allSetsDone && !postExDone;

    final mg = exercise.movement.muscleGroup;
    final isLastForMg = lastExIndexForMg[mg] == index;
    final allMgExDone = _data!.exercises
        .where((e) => e.movement.muscleGroup == mg)
        .every((e) => _postExDone[e.completed.id] == true);
    final showPostMgReopen =
        isLastForMg && allMgExDone && _postMgDone[mg] != true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  exercise.movement.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (showPostExReopen)
                TextButton(
                  onPressed: () => _showPostExerciseSheet(exercise),
                  child: const Text('Rate joint pain'),
                ),
            ],
          ),
        ),
        for (var i = 0; i < exercise.sets.length; i++)
          _buildSetRow(i + 1, exercise.sets[i], exercise.movement, exercise),
        if (showPostMgReopen)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: TextButton.icon(
              onPressed: () => _showPostMuscleGroupSheet(mg),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text('Rate ${_mgLabel(mg)}'),
            ),
          ),
      ],
    );
  }

  Widget _buildSetRow(int setNum, SetData setData, Movement movement,
      ExerciseData exercise) {
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
            _inputField(state.repsCtrl, 'Reps',
                isInt: true, enabled: !state.isChecked),
          ],
          if (movement.isRequiredWeight) ...[
            const SizedBox(width: 8),
            _inputField(state.weightCtrl, 'Weight', enabled: !state.isChecked),
          ],
          if (movement.isRequiredTime) ...[
            const SizedBox(width: 8),
            _inputField(state.timeCtrl, 'Time', enabled: !state.isChecked),
          ],
          const SizedBox(width: 8),
          Checkbox(
            value: state.isChecked,
            onChanged: (canCheck || state.isChecked)
                ? (v) => _onToggle(setData.completed.id, movement, v!, exercise)
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
