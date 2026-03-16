import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/history_data.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/exercise_widget.dart';
import '../widgets/set_ui_state.dart';
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
  final Map<int, SetUiState> _setStates = {};
  // keyed by completedExercise.id
  final Map<int, bool> _postExDone = {};
  final Map<int, SkipReason?> _exerciseSkipReasons = {};
  final Map<int, bool> _isPersistent = {};
  // keyed by MuscleGroup
  final Map<MuscleGroup, bool> _postMgDone = {};
  bool _loading = true;

  // Per-workout timer kill-switch — toggled via the timer widget's icon button.
  bool _timerWorkoutOn = true;

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
    WakelockPlus.disable();
    super.dispose();
  }

  // ── Active exercise ────────────────────────────────────────────────────────

  /// The first exercise that still has work to do (unchecked sets, or sets done
  /// but post-exercise check-in not yet answered). Returns null when the whole
  /// workout is done.
  int? get _activeExerciseId {
    if (_data == null) return null;
    for (final ex in _data!.exercises) {
      if (_exerciseSkipReasons[ex.completed.id] != null) continue;
      final allSetsDone =
          ex.sets.every((s) => _setStates[s.completed.id]?.isChecked ?? false);
      if (!allSetsDone) return ex.completed.id;
      if (_postExDone[ex.completed.id] != true) return ex.completed.id;
    }
    return null;
  }

  /// Effective rest duration for [movement]: per-movement override → global
  /// default. Returns 0 if the timer is disabled for this movement.
  int _effectiveDuration(Movement movement) {
    final perMovement = movement.restSeconds;
    if (perMovement != null) return perMovement; // 0 means disabled
    return AppPreferences.getTimerDefaultSeconds();
  }

  /// Cue text spoken by TTS when the timer reaches zero.
  String? _cueText(ExerciseData exercise) {
    SetData? next;
    for (final s in exercise.sets) {
      if (!(_setStates[s.completed.id]?.isChecked ?? false)) {
        next = s;
        break;
      }
    }
    if (next?.planned == null) return null;
    final ps = next!.planned!;
    final m = exercise.movement;
    final metric = AppPreferences.getUnitsMetric();
    if (m.isRequiredDistance && ps.distance != null) {
      final unit = metric ? 'kilometers' : 'miles';
      return '${_fmt(ps.distance!)} $unit';
    }
    if (m.isRequiredTime && ps.time != null) {
      return '${_fmt(ps.time!)} seconds';
    }
    if (m.isRequiredWeight && ps.weight != null) {
      final unit = metric ? 'kilograms' : 'pounds';
      return '${_fmt(ps.weight!)} $unit';
    }
    return null;
  }

  void _toggleWorkoutTimer() {
    setState(() => _timerWorkoutOn = !_timerWorkoutOn);
    // ExerciseWidget's didUpdateWidget handles stopping its own controller.
  }

  void _applyWakeLock() {
    if (AppPreferences.getTimerKeepAwake()) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _load() async {
    final data = await db.getWorkoutData(widget.completedWorkoutId);

    final newSetStates = <int, SetUiState>{};
    for (final ex in data.exercises) {
      for (final s in ex.sets) {
        final cs = s.completed;
        final ps = s.planned;
        newSetStates[cs.id] = SetUiState(
          reps: cs.reps?.toString() ?? ps?.reps?.toString() ?? '',
          weight: _fmt(cs.weight ?? ps?.weight),
          distance: _fmt(cs.distance ?? ps?.distance),
          time: _fmt(cs.time ?? ps?.time),
          isChecked: WorkoutData.setIsDone(s, ex.movement),
          isSkipped: cs.skipReason != null,
        );
      }
      _postExDone.putIfAbsent(
          ex.completed.id, () => ex.postExerciseCheckin != null);
      _exerciseSkipReasons.putIfAbsent(
          ex.completed.id, () => ex.completed.skipReason);
      _isPersistent.putIfAbsent(
          ex.completed.id, () => ex.completed.isPersistent);
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
      _applyWakeLock();
    }
  }

  String _fmt(double? v) {
    if (v == null) return '';
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  bool get _isFinishable {
    if (_data == null || _setStates.isEmpty) return false;
    for (final ex in _data!.exercises) {
      if (_exerciseSkipReasons[ex.completed.id] != null) continue;
      if (!ex.sets.every(
          (s) => _setStates[s.completed.id]?.isChecked ?? false)) {
        return false;
      }
      if (_postExDone[ex.completed.id] != true) return false;
    }
    final muscleGroups =
        _data!.exercises.map((e) => e.movement.muscleGroup).toSet();
    return muscleGroups.every((mg) {
      final mgExercises =
          _data!.exercises.where((e) => e.movement.muscleGroup == mg);
      if (mgExercises
          .every((e) => _exerciseSkipReasons[e.completed.id] != null)) {
        return true;
      }
      return _postMgDone[mg] == true;
    });
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
      SetData setData, bool checked, ExerciseData exercise) async {
    final setId = setData.completed.id;
    final movement = exercise.movement;
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
        distance: movement.isRequiredDistance
            ? double.parse(state.distanceCtrl.text.trim())
            : null,
        time: movement.isRequiredTime
            ? double.parse(state.timeCtrl.text.trim())
            : null,
      );
      setState(() => _setStates[setId]!.isChecked = true);
    } else {
      // Collect all sets to clear: walk backwards from this set while skipped.
      final setIndex =
          exercise.sets.indexWhere((s) => s.completed.id == setId);
      final toClear = <int>[];
      for (var i = setIndex; i >= 0; i--) {
        final id = exercise.sets[i].completed.id;
        if (_setStates[id]?.isSkipped == true || id == setId) {
          toClear.add(id);
        } else {
          break;
        }
      }
      for (final id in toClear) {
        await db.clearCompletedSet(id);
      }
      setState(() {
        for (final id in toClear) {
          final state = _setStates[id]!;
          final wasSkipped = state.isSkipped;
          state.isChecked = false;
          state.isSkipped = false;
          if (wasSkipped) {
            final sd = exercise.sets.firstWhere((s) => s.completed.id == id);
            final ps = sd.planned;
            state.repsCtrl.text = ps?.reps?.toString() ?? '';
            state.weightCtrl.text = _fmt(ps?.weight);
            state.distanceCtrl.text = _fmt(ps?.distance);
            state.timeCtrl.text = _fmt(ps?.time);
          }
        }
      });

      // Clear post-exercise check-in so user is reprompted after re-completing.
      if (_postExDone[exercise.completed.id] == true) {
        await db.clearPostExerciseCheckin(exercise.completed.id);
        setState(() => _postExDone[exercise.completed.id] = false);
      }
      // Clear MG check-in for the same reason.
      final mg = exercise.movement.muscleGroup;
      if (_postMgDone[mg] == true) {
        await db.clearPostMuscleGroupCheckin(widget.completedWorkoutId, mg);
        setState(() => _postMgDone[mg] = false);
      }
    }

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
    final jointPain = await showModalBottomSheet<Soreness>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
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
              selected: const {},
              emptySelectionAllowed: true,
              onSelectionChanged: (v) => Navigator.pop(ctx, v.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (jointPain == null || !mounted) return;

    await db.savePostExerciseCheckin(
      PostExerciseCheckinsCompanion.insert(
        completedExerciseId: exercise.completed.id,
        jointPain: jointPain,
      ),
    );

    setState(() => _postExDone[exercise.completed.id] = true);

    final mg = exercise.movement.muscleGroup;
    final mgExercises =
        _data!.exercises.where((e) => e.movement.muscleGroup == mg).toList();
    final allMgSkipped =
        mgExercises.every((e) => _exerciseSkipReasons[e.completed.id] != null);
    final allMgDone = !allMgSkipped &&
        mgExercises.every((e) =>
            _postExDone[e.completed.id] == true ||
            _exerciseSkipReasons[e.completed.id] != null);
    if (allMgDone && _postMgDone[mg] != true && mounted) {
      await _showPostMuscleGroupSheet(mg);
    }
  }

  Future<void> _showPostMuscleGroupSheet(MuscleGroup muscleGroup) async {
    Effort? effort;
    Volume? volume;
    var effortSet = false;
    var volumeSet = false;

    final result = await showModalBottomSheet<(Effort, Volume)>(
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
                selected: effort != null ? {effort!} : const {},
                emptySelectionAllowed: true,
                onSelectionChanged: (v) {
                  setSheet(() => effort = v.first);
                  effortSet = true;
                  if (volumeSet) Navigator.pop(ctx, (effort!, volume!));
                },
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
                selected: volume != null ? {volume!} : const {},
                emptySelectionAllowed: true,
                onSelectionChanged: (v) {
                  setSheet(() => volume = v.first);
                  volumeSet = true;
                  if (effortSet) Navigator.pop(ctx, (effort!, volume!));
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    await db.savePostMuscleGroupCheckin(
      PostMuscleGroupCheckinsCompanion.insert(
        completedWorkoutId: widget.completedWorkoutId,
        muscleGroup: muscleGroup,
        effortLevel: result.$1,
        volumeLevel: result.$2,
      ),
    );

    setState(() => _postMgDone[muscleGroup] = true);
  }

  String _skipReasonLabel(SkipReason r) => switch (r) {
        SkipReason.systemicFatigue => 'Systemic Fatigue',
        SkipReason.muscleFatigue => 'Muscle Fatigue',
        SkipReason.jointPain => 'Joint Pain',
        SkipReason.time => 'Time',
        SkipReason.musclePain => 'Muscle Pain',
        SkipReason.softTissuePainOther => 'Soft Tissue / Other',
        SkipReason.dontLikeTheExercise => "Don't Like the Exercise",
      };

  Future<void> _showSkipReasonSheet(
      SetData setData, ExerciseData exercise) async {
    SkipReason? selected;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
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
            Text('Skip Reason', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final reason in SkipReason.values)
              ListTile(
                title: Text(_skipReasonLabel(reason)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  selected = reason;
                  Navigator.pop(ctx);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _skipSets(setData, exercise, selected!);
  }

  Future<void> _skipSets(
      SetData setData, ExerciseData exercise, SkipReason reason) async {
    final setIndex =
        exercise.sets.indexWhere((s) => s.completed.id == setData.completed.id);
    final toSkip = [
      for (var i = setIndex; i < exercise.sets.length; i++)
        if (!(_setStates[exercise.sets[i].completed.id]?.isChecked ?? false))
          exercise.sets[i].completed.id,
    ];

    for (final id in toSkip) {
      await db.skipSet(id, reason);
    }

    setState(() {
      for (final id in toSkip) {
        final state = _setStates[id]!;
        state.isSkipped = true;
        state.isChecked = true;
        state.repsCtrl.clear();
        state.weightCtrl.clear();
        state.distanceCtrl.clear();
        state.timeCtrl.clear();
      }
    });

    if (_postExDone[exercise.completed.id] != true) {
      final allSetsDone = exercise.sets
          .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
      if (allSetsDone && mounted) {
        await _showPostExerciseSheet(exercise);
      }
    }
  }

  Future<void> _showExerciseSkipSheet(ExerciseData exercise) async {
    SkipReason? selected;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
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
            Text('Skip Exercise', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final reason in SkipReason.values)
              ListTile(
                title: Text(_skipReasonLabel(reason)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  selected = reason;
                  Navigator.pop(ctx);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _skipExercise(exercise, selected!);
  }

  Future<void> _skipExercise(ExerciseData exercise, SkipReason reason) async {
    await db.skipExercise(exercise.completed.id, reason);
    setState(() {
      _exerciseSkipReasons[exercise.completed.id] = reason;
      for (final s in exercise.sets) {
        final state = _setStates[s.completed.id]!;
        state.isSkipped = true;
        state.isChecked = true;
        state.repsCtrl.clear();
        state.weightCtrl.clear();
        state.distanceCtrl.clear();
        state.timeCtrl.clear();
      }
    });
  }

  Future<void> _addSet(ExerciseData exercise) async {
    if (_postExDone[exercise.completed.id] == true) {
      await db.clearPostExerciseCheckin(exercise.completed.id);
      setState(() => _postExDone[exercise.completed.id] = false);
    }
    final mg = exercise.movement.muscleGroup;
    if (_postMgDone[mg] == true) {
      await db.clearPostMuscleGroupCheckin(widget.completedWorkoutId, mg);
      setState(() => _postMgDone[mg] = false);
    }
    await db.addSet(exercise.completed.id);
    await _load();
  }

  Future<void> _deleteSet(SetData setData, ExerciseData exercise) async {
    await db.deleteSet(setData.completed.id);
    _setStates.remove(setData.completed.id)?.dispose();
    await _load();
    if (!mounted) return;
    final updatedEx = _data!.exercises
        .firstWhere((e) => e.completed.id == exercise.completed.id);
    if (_postExDone[updatedEx.completed.id] != true) {
      final allSetsDone = updatedEx.sets
          .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
      if (allSetsDone) {
        await _showPostExerciseSheet(updatedEx);
      }
    }
  }

  Future<void> _unskipExercise(ExerciseData exercise) async {
    await db.unskipExercise(exercise.completed.id);
    final mg = exercise.movement.muscleGroup;
    if (_postMgDone[mg] == true) {
      await db.clearPostMuscleGroupCheckin(widget.completedWorkoutId, mg);
    }
    setState(() {
      _exerciseSkipReasons[exercise.completed.id] = null;
      _postExDone[exercise.completed.id] = false;
      _postMgDone[mg] = false;
      for (final s in exercise.sets) {
        final state = _setStates[s.completed.id]!;
        state.isChecked = false;
        state.isSkipped = false;
        final ps = s.planned;
        state.repsCtrl.text = ps?.reps?.toString() ?? '';
        state.weightCtrl.text = _fmt(ps?.weight);
        state.distanceCtrl.text = _fmt(ps?.distance);
        state.timeCtrl.text = _fmt(ps?.time);
      }
    });
  }

  Future<void> _togglePersistence(ExerciseData exercise) async {
    final next = !(_isPersistent[exercise.completed.id] ?? true);
    await db.setExercisePersistence(exercise.completed.id, next);
    setState(() => _isPersistent[exercise.completed.id] = next);
  }

  Future<void> _showMovementHistorySheet(ExerciseData exercise) async {
    final entries = await db.getMovementHistory(exercise.movement.id);

    if (!mounted) return;

    final mesoOrder = <int>[];
    final byMeso = <int, List<MovementHistoryEntry>>{};
    for (final entry in entries) {
      if (!byMeso.containsKey(entry.mesoId)) {
        mesoOrder.add(entry.mesoId);
        byMeso[entry.mesoId] = [];
      }
      byMeso[entry.mesoId]!.add(entry);
    }

    final weightUnit = AppPreferences.getUnitsMetric() ? 'kg' : 'lbs';

    String fmt(double? v) {
      if (v == null) return '—';
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    }

    String setLine(CompletedSet s, Movement m) {
      if (s.skipReason != null) return 'Skipped — ${_skipReasonLabel(s.skipReason!)}';
      final parts = <String>[];
      if (m.isRequiredReps) parts.add(s.reps != null ? '${s.reps} reps' : '—');
      if (m.isRequiredWeight) {
        parts.add(s.weight != null ? '${fmt(s.weight)} $weightUnit' : '—');
      }
      if (m.isRequiredTime) parts.add(s.time != null ? '${fmt(s.time)}s' : '—');
      return parts.join(' × ');
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                exercise.movement.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No history yet.'),
              )
            else
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    for (final mesoId in mesoOrder) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Text(
                          byMeso[mesoId]!.first.mesoName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      for (final entry in byMeso[mesoId]!) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 2),
                          child: Text(
                            '${_fmtDate(entry.workoutDate)}  ·  Week ${entry.weekNumber}  ·  ${entry.workoutName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (entry.exercise.skipReason != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              'Exercise skipped — ${_skipReasonLabel(entry.exercise.skipReason!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          )
                        else
                          for (var i = 0; i < entry.sets.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 1),
                              child: Text(
                                'Set ${i + 1}: ${setLine(entry.sets[i], exercise.movement)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}';
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
    await AppPreferences.setCurrentCompletedWorkoutId(null);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  /// True when the exercise at [index] is unblocked.
  bool _isPrevExDone(int index) {
    if (index == 0) return true;
    final exercises = _data!.exercises;
    final prev = exercises[index - 1];
    if (_exerciseSkipReasons[prev.completed.id] != null) return true;
    final allSetsDone =
        prev.sets.every((s) => _setStates[s.completed.id]?.isChecked ?? false);
    if (!allSetsDone || _postExDone[prev.completed.id] != true) return false;
    final mg = prev.movement.muscleGroup;
    final lastMgIndex =
        exercises.lastIndexWhere((e) => e.movement.muscleGroup == mg);
    if (lastMgIndex == index - 1) {
      final allMgSkipped = exercises
          .where((e) => e.movement.muscleGroup == mg)
          .every((e) => _exerciseSkipReasons[e.completed.id] != null);
      if (!allMgSkipped && _postMgDone[mg] != true) return false;
    }
    return true;
  }

  String _mgLabel(MuscleGroup mg) {
    final name = mg.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  void _propagateWeight(ExerciseData exercise, SetData setData, String value) {
    final setIndex = exercise.sets
        .indexWhere((s) => s.completed.id == setData.completed.id);
    for (var i = setIndex + 1; i < exercise.sets.length; i++) {
      final id = exercise.sets[i].completed.id;
      final s = _setStates[id];
      if (s != null && !s.isChecked && !s.isSkipped) {
        s.weightCtrl.text = value;
      }
    }
  }

  void _propagateDistance(ExerciseData exercise, SetData setData, String value) {
    final setIndex = exercise.sets
        .indexWhere((s) => s.completed.id == setData.completed.id);
    for (var i = setIndex + 1; i < exercise.sets.length; i++) {
      final id = exercise.sets[i].completed.id;
      final s = _setStates[id];
      if (s != null && !s.isChecked && !s.isSkipped) {
        s.distanceCtrl.text = value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutName),
          automaticallyImplyLeading: false,
          actions: [
            AppNavMenu(
              current: AppScreen.workout,
              activeWorkoutId: widget.completedWorkoutId,
              activeWorkoutName: widget.workoutName,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _data!;
    final lastExIndexForMg = _lastExIndexForMg();
    final activeExId = _activeExerciseId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.workout,
            activeWorkoutId: widget.completedWorkoutId,
            activeWorkoutName: widget.workoutName,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (var i = 0; i < data.exercises.length; i++)
                  _buildExerciseWidget(
                      data.exercises[i], i, lastExIndexForMg, activeExId),
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

  Widget _buildExerciseWidget(ExerciseData exercise, int index,
      Map<MuscleGroup, int> lastExIndexForMg, int? activeExId) {
    final isActive = exercise.completed.id == activeExId;
    final isExSkipped = _exerciseSkipReasons[exercise.completed.id] != null;
    final isExLocked = !_isPrevExDone(index);
    final allSetsDone = exercise.sets
        .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
    final postExDone = _postExDone[exercise.completed.id] == true;
    final showPostExReopen = allSetsDone && !postExDone;
    final anySetChecked = exercise.sets
        .any((s) => _setStates[s.completed.id]?.isChecked ?? false);

    final mg = exercise.movement.muscleGroup;
    final isLastForMg = lastExIndexForMg[mg] == index;
    final mgExercises =
        _data!.exercises.where((e) => e.movement.muscleGroup == mg).toList();
    final allMgSkipped =
        mgExercises.every((e) => _exerciseSkipReasons[e.completed.id] != null);
    final allMgExDone = !allMgSkipped &&
        mgExercises.every((e) =>
            _postExDone[e.completed.id] == true ||
            _exerciseSkipReasons[e.completed.id] != null);
    final showPostMgReopen =
        isLastForMg && allMgExDone && _postMgDone[mg] != true;

    return ExerciseWidget(
      key: ValueKey(exercise.completed.id),
      exercise: exercise,
      isActive: isActive,
      isExSkipped: isExSkipped,
      isExLocked: isExLocked,
      allSetsDone: allSetsDone,
      showPostExReopen: showPostExReopen,
      anySetChecked: anySetChecked,
      showPostMgReopen: showPostMgReopen,
      mgLabel: _mgLabel(mg),
      persistent: _isPersistent[exercise.completed.id] ?? true,
      timerEnabled: AppPreferences.getTimerEnabled(),
      workoutTimerOn: _timerWorkoutOn,
      timerDurationSeconds: _effectiveDuration(exercise.movement),
      cueText: _cueText(exercise),
      setStates: _setStates,
      onToggleWorkoutTimer: _toggleWorkoutTimer,
      onShowPostExerciseSheet: () => _showPostExerciseSheet(exercise),
      onShowPostMuscleGroupSheet: () => _showPostMuscleGroupSheet(mg),
      onShowExerciseSkipSheet: () => _showExerciseSkipSheet(exercise),
      onUnskipExercise: () => _unskipExercise(exercise),
      onAddSet: () => _addSet(exercise),
      onToggleSet: (setData, checked) => _onToggle(setData, checked, exercise),
      onShowSetSkipSheet: (setData) => _showSkipReasonSheet(setData, exercise),
      onDeleteSet: (setData) => _deleteSet(setData, exercise),
      onTogglePersistence: () => _togglePersistence(exercise),
      onShowMovementHistorySheet: () => _showMovementHistorySheet(exercise),
      onWeightChanged: (setData, value) =>
          _propagateWeight(exercise, setData, value),
      onDistanceChanged: (setData, value) =>
          _propagateDistance(exercise, setData, value),
    );
  }
}
