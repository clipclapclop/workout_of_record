import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../widgets/app_nav_menu.dart';
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
  final Map<int, SkipReason?> _exerciseSkipReasons = {};
  final Map<int, bool> _isPersistent = {};
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
            final setData =
                exercise.sets.firstWhere((s) => s.completed.id == id);
            final ps = setData.planned;
            state.repsCtrl.text = ps?.reps?.toString() ?? '';
            state.weightCtrl.text = _fmt(ps?.weight);
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

    // If all exercises for this muscle group now have check-ins (or are
    // skipped), and the MG itself isn't all-skipped, show MG sheet.
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
        state.timeCtrl.text = _fmt(ps?.time);
      }
    });
  }

  Future<void> _togglePersistence(ExerciseData exercise) async {
    final next = !(_isPersistent[exercise.completed.id] ?? true);
    await db.setExercisePersistence(exercise.completed.id, next);
    setState(() => _isPersistent[exercise.completed.id] = next);
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
    final isExSkipped = _exerciseSkipReasons[exercise.completed.id] != null;
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

    final persistent = _isPersistent[exercise.completed.id] ?? true;

    Widget headerTrailing;
    if (isExSkipped) {
      headerTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _unskipExercise(exercise),
            child: const Text('Unskip'),
          ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (_) => _togglePersistence(exercise),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ExMenuAction.togglePersistent,
                child: Text(persistent ? "Don't carry forward" : 'Carry forward'),
              ),
            ],
          ),
        ],
      );
    } else {
      headerTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPostExReopen)
            TextButton(
              onPressed: () => _showPostExerciseSheet(exercise),
              child: const Text('Rate joint pain'),
            ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _ExMenuAction.skipExercise) {
                _showExerciseSkipSheet(exercise);
              } else if (action == _ExMenuAction.addSet) {
                _addSet(exercise);
              } else {
                _togglePersistence(exercise);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ExMenuAction.skipExercise,
                enabled: !anySetChecked,
                child: const Text('Skip Exercise'),
              ),
              PopupMenuItem(
                value: _ExMenuAction.addSet,
                child: const Text('Add Set'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ExMenuAction.togglePersistent,
                child: Text(persistent ? "Don't carry forward" : 'Carry forward'),
              ),
            ],
          ),
        ],
      );
    }

    final header = Padding(
      padding: isExSkipped
          ? const EdgeInsets.only(top: 8, bottom: 4)
          : const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise.movement.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (exercise.movement.link != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => launchUrl(
                Uri.parse(exercise.movement.link!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          headerTrailing,
        ],
      ),
    );

    final setRows = [
      for (var i = 0; i < exercise.sets.length; i++)
        _buildSetRow(i + 1, exercise.sets[i], exercise.movement, exercise,
            isExSkipped: isExSkipped),
    ];

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (exercise.movement.note1 != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              exercise.movement.note1!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...setRows,
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

    if (isExSkipped) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: column,
      );
    }
    return column;
  }

  Widget _buildSetRow(int setNum, SetData setData, Movement movement,
      ExerciseData exercise, {bool isExSkipped = false}) {
    final state = _setStates[setData.completed.id]!;
    final canCheck = state.canCheck(movement);

    return Container(
      decoration: state.isSkipped
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
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
            onChanged: isExSkipped
                ? null
                : (canCheck || state.isChecked)
                    ? (v) =>
                        _onToggle(setData.completed.id, movement, v!, exercise)
                    : null,
          ),
          PopupMenuButton<_SetMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _SetMenuAction.skip) {
                _showSkipReasonSheet(setData, exercise);
              } else if (action == _SetMenuAction.delete) {
                _deleteSet(setData, exercise);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SetMenuAction.skip,
                enabled: !state.isChecked && !isExSkipped,
                child: const Text('Skip'),
              ),
              if (setData.planned == null)
                PopupMenuItem(
                  value: _SetMenuAction.delete,
                  enabled: !state.isChecked,
                  child: const Text('Delete'),
                ),
            ],
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

enum _SetMenuAction { skip, delete }

enum _ExMenuAction { skipExercise, addSet, togglePersistent }

class _SetUiState {
  _SetUiState({
    required this.isChecked,
    required this.isSkipped,
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
  bool isSkipped;

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
