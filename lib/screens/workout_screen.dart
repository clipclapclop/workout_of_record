import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/history_data.dart';
import '../db/planning.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import '../services/backup_service.dart';
import '../services/workout_cue_text.dart';
import '../services/workout_foreground_service.dart';
import '../workout_units.dart';
import '../widgets/app_nav_menu.dart';
import 'chat_screen.dart';
import '../widgets/empty_workout_view.dart';
import '../widgets/exercise_widget.dart';
import '../widgets/rest_timer_controller.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/meso_calendar_sheet.dart';
import '../widgets/movement_picker_sheet.dart';
import '../widgets/set_ui_state.dart';
import 'home_screen.dart';

class WorkoutScreen extends StatefulWidget {
  static const routeName = '/active-workout';

  const WorkoutScreen({
    super.key,
    required this.completedWorkoutId,
    required this.workoutName,
    required this.mesocycleId,
  });

  final int completedWorkoutId;
  final String workoutName;
  final int mesocycleId;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutData? _data;
  final Map<int, SetUiState> _setStates = {};
  // keyed by completedExercise.id
  final Map<int, bool> _postExDone = {};
  final Map<int, SkipReason?> _exerciseSkipReasons = {};
  final Map<int, Persistence> _persistence = {};
  // keyed by MuscleGroup
  final Map<MuscleGroup, bool> _postMgDone = {};
  bool _loading = true;

  // AI recommendation retry state
  List<String> _aiErrors = [];
  bool _aiRetrying = false;

  // Per-workout timer kill-switch — always on (no UI to toggle).
  static const _timerWorkoutOn = true;

  late RestTimerController _timerController;
  int? _timerActiveExId;
  String? _timerCueText;

  @override
  void initState() {
    super.initState();
    _timerController = RestTimerController(durationSeconds: 0);
    _timerController.addListener(_onTimerControllerChanged);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    // Load first so a database failure cannot leave an orphaned foreground
    // service. Timer updates are retained and replayed when the task starts.
    await _load();
    if (!mounted) return;

    final serviceStarted = await WorkoutForegroundService.start();
    if (!mounted) {
      await WorkoutForegroundService.stop();
      return;
    }
    if (!serviceStarted) {
      // Keep the latest timer state queued; a late task heartbeat replays it.
      _pushTimerToService();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Background timer alerts are unavailable. Keep Workout of Record '
            'visible for timer cues.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
      return;
    }
    // The task's readiness signal replays the latest timer or widget-cued
    // state retained while the service was starting.
  }

  @override
  void dispose() {
    for (final s in _setStates.values) {
      s.dispose();
    }
    _timerController.removeListener(_onTimerControllerChanged);
    _timerController.dispose();
    WakelockPlus.disable();
    WorkoutForegroundService.stop();
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

  /// Notification set info line, e.g. "Set 2/4 · 10 reps · 80 lbs".
  String? _setInfoText(ExerciseData exercise) {
    final sets = exercise.sets;
    if (sets.isEmpty) return null;
    final nextIdx = sets.indexWhere(
        (s) => !(_setStates[s.completed.id]?.isChecked ?? false));
    if (nextIdx < 0) return null;
    final setNum = nextIdx + 1;
    final ps = sets[nextIdx].planned;
    final m = exercise.movement;
    final parts = <String>['Set $setNum/${sets.length}'];
    if (m.isRequiredReps && ps?.reps != null) parts.add('${ps!.reps} reps');
    if (m.isRequiredWeight && ps?.weight != null) {
      parts.add('${_fmt(ps!.weight!)} ${WorkoutUnits.weight}');
    }
    if (m.isRequiredDistance && ps?.distance != null) {
      parts.add('${_fmt(ps!.distance!)} ${WorkoutUnits.distance}');
    }
    if (m.isRequiredTime && ps?.time != null) {
      parts.add('${_fmt(ps!.time!)}s');
    }
    return parts.join(' · ');
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
    return buildWorkoutCueText(exercise.movement, next!.planned!);
  }

  void _syncTimer() {
    if (!AppPreferences.getTimerEnabled() || !_timerWorkoutOn || _data == null) {
      _timerController.stop();
      _timerActiveExId = null;
      _timerCueText = null;
      _pushTimerToService();
      return;
    }
    final activeId = _activeExerciseId;
    if (activeId == null) {
      _timerController.stop();
      _timerActiveExId = null;
      _timerCueText = null;
      _pushTimerToService();
      return;
    }
    final activeEx =
        _data!.exercises.firstWhere((e) => e.completed.id == activeId);
    _timerActiveExId = activeId;
    _timerCueText = _cueText(activeEx);

    // Loading a workout or moving between exercises only updates the idle
    // duration and next-set context. A running rest belongs to the set that
    // triggered it and must continue through post-exercise questions.
    _timerController.setDurationWhenIdle(_effectiveDuration(activeEx.movement));
    _pushTimerToService();
  }

  bool _isFinalUsableSet(SetData interactedSet) {
    final excludedSetIds = <int>{};
    final orderedSetIds = <int>[];
    for (final exercise in _data!.exercises) {
      final exerciseSkipped =
          _exerciseSkipReasons[exercise.completed.id] != null;
      for (final set in exercise.sets) {
        orderedSetIds.add(set.completed.id);
        if (exerciseSkipped ||
            (_setStates[set.completed.id]?.isSkipped ?? false)) {
          excludedSetIds.add(set.completed.id);
        }
      }
    }
    return isFinalUsableWorkoutSet(
      interactedSetId: interactedSet.completed.id,
      orderedSetIds: orderedSetIds,
      excludedSetIds: excludedSetIds,
    );
  }

  void _onTimerReset(SetData interactedSet, ExerciseData exercise) {
    if (_isFinalUsableSet(interactedSet)) {
      _timerController.stop();
      _timerActiveExId = null;
      _timerCueText = null;
      _pushTimerToService();
      if (mounted) setState(() {});
      return;
    }

    final duration = _effectiveDuration(exercise.movement);
    if (duration <= 0 ||
        !AppPreferences.getTimerEnabled() ||
        !_timerWorkoutOn) {
      _timerController.stop();
      _pushTimerToService();
      return;
    }

    _timerActiveExId = exercise.completed.id;
    _timerCueText = _cueText(exercise);
    _timerController.setDuration(duration);
    _timerController.start();
    _pushTimerToService();
    if (mounted) setState(() {});
  }

  void _onTimerControllerChanged() {
    _pushTimerToService();
  }

  void _pushTimerToService() {
    if (_timerActiveExId == null || _data == null) {
      WorkoutForegroundService.clearTimer();
      return;
    }
    ExerciseData? activeEx;
    for (final ex in _data!.exercises) {
      if (ex.completed.id == _timerActiveExId) {
        activeEx = ex;
        break;
      }
    }
    if (activeEx == null || !_timerController.isRunning) {
      WorkoutForegroundService.clearTimer();
      return;
    }
    WorkoutForegroundService.clearCued();
    WorkoutForegroundService.update(
      exerciseName: activeEx.movement.name,
      cueText: _timerCueText,
      setInfo: _setInfoText(activeEx),
      sound: AppPreferences.getTimerSound(),
      haptic: AppPreferences.getTimerHaptic(),
      getReadyChimes: AppPreferences.getTimerGetReadyChimes(),
      timerEndsAt: DateTime.now()
          .add(Duration(milliseconds: _timerController.remainingMs)),
    );
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
      _persistence.putIfAbsent(
          ex.completed.id, () => ex.completed.persistence);
    }
    final currentMuscleGroups = {
      for (final exercise in data.exercises) exercise.movement.muscleGroup,
    };
    _postMgDone.removeWhere((group, _) => !currentMuscleGroups.contains(group));
    for (final group in currentMuscleGroups) {
      _postMgDone[group] = false;
    }
    for (final mgCheckin in data.postMuscleGroupCheckins) {
      if (currentMuscleGroups.contains(mgCheckin.muscleGroup)) {
        _postMgDone[mgCheckin.muscleGroup] = true;
      }
    }

    // Check for AI recommendation failures.
    final aiErrors = db.consumeAiErrors();

    if (mounted) {
      setState(() {
        _data = data;
        for (final entry in newSetStates.entries) {
          _setStates.putIfAbsent(entry.key, () => entry.value);
        }
        _loading = false;
        if (aiErrors.isNotEmpty) _aiErrors = aiErrors;
      });
      _applyWakeLock();
      _syncTimer();
    }
  }

  Future<void> _retryAi() async {
    setState(() => _aiRetrying = true);
    try {
      final workoutId = _data!.workout.id;
      final count = await db.retryAiForPlannedWorkout(workoutId);
      if (count > 0 && mounted) {
        // Clear set states so _load re-reads the new planned values.
        _setStates.clear();
        await _load();
      }
      if (mounted) {
        setState(() {
          _aiErrors = [];
          _aiRetrying = false;
        });
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI updated $count exercise${count > 1 ? 's' : ''}.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI retry failed. Using built-in progression.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aiRetrying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: $e')),
        );
      }
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
    _syncTimer();
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
    Pump? pump;
    Volume? volume;
    var effortSet = false;
    var pumpSet = false;
    var volumeSet = false;

    final result = await showModalBottomSheet<(Effort, Pump, Volume)>(
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
                      value: Effort.easy, label: Text('Easy')),
                  ButtonSegment(value: Effort.good, label: Text('Good')),
                  ButtonSegment(value: Effort.hard, label: Text('Hard')),
                  ButtonSegment(
                      value: Effort.tooHard, label: Text('Too Hard')),
                ],
                selected: effort != null ? {effort!} : const {},
                emptySelectionAllowed: true,
                onSelectionChanged: (v) {
                  setSheet(() => effort = v.first);
                  effortSet = true;
                  if (pumpSet && volumeSet) {
                    Navigator.pop(ctx, (effort!, pump!, volume!));
                  }
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              const Text('How was the pump?'),
              const SizedBox(height: 8),
              SegmentedButton<Pump>(
                segments: const [
                  ButtonSegment(
                      value: Pump.none, label: Text('None')),
                  ButtonSegment(value: Pump.aLittle, label: Text('A Little')),
                  ButtonSegment(value: Pump.good, label: Text('Good')),
                  ButtonSegment(
                      value: Pump.amazing, label: Text('Amazing')),
                ],
                selected: pump != null ? {pump!} : const {},
                emptySelectionAllowed: true,
                onSelectionChanged: (v) {
                  setSheet(() => pump = v.first);
                  pumpSet = true;
                  if (effortSet && volumeSet) {
                    Navigator.pop(ctx, (effort!, pump!, volume!));
                  }
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
                  if (effortSet && pumpSet) {
                    Navigator.pop(ctx, (effort!, pump!, volume!));
                  }
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
        pumpLevel: result.$2,
        volumeLevel: result.$3,
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
    await db.skipSet(setData.completed.id, reason);

    setState(() {
      final state = _setStates[setData.completed.id]!;
      state.isSkipped = true;
      state.isChecked = true;
      state.repsCtrl.clear();
      state.weightCtrl.clear();
      state.distanceCtrl.clear();
      state.timeCtrl.clear();
    });

    if (_postExDone[exercise.completed.id] != true) {
      final allSetsDone = exercise.sets
          .every((s) => _setStates[s.completed.id]?.isChecked ?? false);
      if (allSetsDone && mounted) {
        await _showPostExerciseSheet(exercise);
      }
    }
    _syncTimer();
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
    _syncTimer();
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
    String? lastWeight;
    String? lastDistance;
    if (exercise.sets.isNotEmpty) {
      final lastState = _setStates[exercise.sets.last.completed.id];
      if (lastState != null) {
        final w = lastState.weightCtrl.text.trim();
        final d = lastState.distanceCtrl.text.trim();
        if (w.isNotEmpty) lastWeight = w;
        if (d.isNotEmpty) lastDistance = d;
      }
    }
    await db.addSet(exercise.completed.id);
    await _load();
    if (lastWeight != null || lastDistance != null) {
      final updatedEx = _data?.exercises
          .firstWhere((e) => e.completed.id == exercise.completed.id);
      if (updatedEx != null && updatedEx.sets.isNotEmpty) {
        final newState = _setStates[updatedEx.sets.last.completed.id];
        if (newState != null && !newState.isChecked && !newState.isSkipped) {
          setState(() {
            if (lastWeight != null) newState.weightCtrl.text = lastWeight;
            if (lastDistance != null) newState.distanceCtrl.text = lastDistance;
          });
        }
      }
    }
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
    _syncTimer();
  }

  Future<void> _togglePersistence(ExerciseData exercise) async {
    final current =
        _persistence[exercise.completed.id] ?? Persistence.persistent;
    final next = current == Persistence.persistent
        ? Persistence.singleUse
        : Persistence.persistent;
    await db.setPersistence(exercise.completed.id, next);
    setState(() => _persistence[exercise.completed.id] = next);
  }

  Future<void> _toggleAutoProgress(ExerciseData exercise) async {
    await db.setExerciseAutoProgress(
        exercise.completed.id, !exercise.completed.autoProgress);
    await _load();
  }

  Future<void> _addExercise({ExerciseData? after}) async {
    final movs = await db.getMovements();
    if (!mounted) return;
    final mesoId = AppPreferences.getCurrentMesocycleId();
    await showMovementPickerSheet(
      context: context,
      allMovements: movs,
      alreadyAdded: {
        for (final ex in _data!.exercises) ex.completed.movementId,
      },
      onAdd: (m) async {
        final defaults = mesoId != null
            ? await db.getHistoricalSetDefaults(m.id, mesoId, m)
            : const [PlannedSetValues(), PlannedSetValues()];
        await db.addExerciseAfter(
          widget.completedWorkoutId,
          after?.completed.orderIndex ?? -1,
          m.id,
          defaults: defaults,
        );
        if (mounted) await _load();
        // Fire AI refinement in the background so the user sees heuristic
        // values immediately and the refined values whenever the single AI
        // call returns.
        if (AppPreferences.getAiEnabled()) {
          unawaited(db
              .refineAiForAddedExercise(widget.completedWorkoutId, m.id)
              .then((_) {
            if (mounted) _load();
          }).catchError((_) {
            // Refinement errors are logged inside computeAiRecommendation;
            // swallow here so they don't become unhandled futures.
          }));
        }
      },
    );
  }

  Future<void> _moveExerciseUp(int index) async {
    final exA = _data!.exercises[index];
    final exB = _data!.exercises[index - 1];
    await db.swapExerciseOrder(
      exA.completed.id,
      exA.completed.orderIndex,
      exB.completed.id,
      exB.completed.orderIndex,
    );
    await _load();
  }

  Future<void> _moveExerciseDown(int index) async {
    final exA = _data!.exercises[index];
    final exB = _data!.exercises[index + 1];
    await db.swapExerciseOrder(
      exA.completed.id,
      exA.completed.orderIndex,
      exB.completed.id,
      exB.completed.orderIndex,
    );
    await _load();
  }

  Future<void> _editNote(ExerciseData exercise) async {
    final movement = exercise.movement;
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => _NoteDialog(initialText: movement.note1 ?? ''),
    );
    if (result == null) return;
    final trimmed = result.trim().isEmpty ? null : result.trim();
    await db.updateMovement(
      MovementsCompanion(id: Value(movement.id), note1: Value(trimmed)),
    );
    await _load();
  }

  Future<void> _deleteExercise(ExerciseData exercise) async {
    await db.deleteExercise(exercise.completed.id);
    _setStates.removeWhere((key, _) =>
        exercise.sets.any((s) => s.completed.id == key));
    _postExDone.remove(exercise.completed.id);
    _exerciseSkipReasons.remove(exercise.completed.id);
    _persistence.remove(exercise.completed.id);
    await _load();
  }

  Future<void> _replaceExercise(ExerciseData exercise) async {
    final movs = await db.getMovements();
    if (!mounted) return;
    await showMovementPickerSheet(
      context: context,
      allMovements: movs,
      alreadyAdded: {
        for (final ex in _data!.exercises)
          if (ex.completed.id != exercise.completed.id) ex.completed.movementId,
      },
      onAdd: (m) async {
        await db.replaceExercise(
          exercise.completed.id,
          m.id,
          exercise.completed.orderIndex,
          widget.completedWorkoutId,
        );
        if (mounted) await _load();
      },
    );
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

    const weightUnit = WorkoutUnits.weight;

    String fmt(double? v) {
      if (v == null) return '—';
      return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    }

    String setLine(CompletedSet s, Movement m) {
      if (s.skipReason != null) {
        return 'Skipped — ${_skipReasonLabel(s.skipReason!)}';
      }
      final parts = <String>[];
      if (m.isRequiredWeight) {
        parts.add(s.weight != null ? '${fmt(s.weight)} $weightUnit' : '—');
      }
      if (m.isRequiredReps) parts.add(s.reps != null ? '${s.reps} reps' : '—');
      if (m.isRequiredDistance) {
        const distUnit = WorkoutUnits.distance;
        parts.add(s.distance != null ? '${fmt(s.distance)} $distUnit' : '—');
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

    _maybeBackupInBackground();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  void _maybeBackupInBackground() {
    if (!AppPreferences.getBackupEnabled()) return;
    if (!AppPreferences.getAutoBackupEnabled()) return;
    final dir = AppPreferences.getBackupDirectoryPath();
    if (dir == null) return;

    unawaited(
      BackupService.backup(dir).then((_) {
        AppPreferences.setLastBackupError(null);
      }).catchError((Object e) {
        AppPreferences.setLastBackupError(e.toString());
      }),
    );
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
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => showMesoCalendarSheet(
                  context, widget.mesocycleId, widget.completedWorkoutId),
            ),
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
          if (AppPreferences.getTimerEnabled() &&
              _timerWorkoutOn &&
              _timerActiveExId != null &&
              _timerController.durationSeconds > 0)
            RestTimerWidget(
              controller: _timerController,
              cueText: _timerCueText,
            ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'AI Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  initialContext:
                      'The user is currently in a workout: "${widget.workoutName}".\n'
                      'Completed workout ID: ${widget.completedWorkoutId}.',
                  activeWorkoutId: widget.completedWorkoutId,
                  activeWorkoutName: widget.workoutName,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => showMesoCalendarSheet(
                context, widget.mesocycleId, widget.completedWorkoutId),
          ),
          AppNavMenu(
            current: AppScreen.workout,
            activeWorkoutId: widget.completedWorkoutId,
            activeWorkoutName: widget.workoutName,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_aiErrors.isNotEmpty)
            MaterialBanner(
              content: const Text(
                  'AI recommendations failed. Using built-in progression.'),
              leading: const Icon(Icons.warning_amber),
              actions: [
                if (_aiRetrying)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _retryAi,
                    child: const Text('Retry AI'),
                  ),
                TextButton(
                  onPressed: () => setState(() => _aiErrors = []),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
              children: [
                if (data.exercises.isEmpty)
                  EmptyWorkoutView(
                    onAddExercise: () => _addExercise(),
                    onFinishWorkout: _finishWorkout,
                  ),
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

  bool _isExNotStarted(ExerciseData ex) {
    return _exerciseSkipReasons[ex.completed.id] == null &&
        !ex.sets.any((s) => _setStates[s.completed.id]?.isChecked ?? false);
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

    final isNotStarted = !isExSkipped && !anySetChecked;
    final hasPersistedSetActivity = exercise.sets.any((set) {
      final completed = set.completed;
      return completed.reps != null ||
          completed.weight != null ||
          completed.distance != null ||
          completed.time != null ||
          completed.skipReason != null;
    });
    final canReplace =
        isNotStarted && !hasPersistedSetActivity && !postExDone;
    final exercises = _data!.exercises;
    final canMoveUp = isNotStarted &&
        index > 0 &&
        _isExNotStarted(exercises[index - 1]);
    final canMoveDown = isNotStarted &&
        index < exercises.length - 1 &&
        _isExNotStarted(exercises[index + 1]);

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
      persistence: _persistence[exercise.completed.id] ?? Persistence.persistent,
      setStates: _setStates,
      onTimerReset: (setData) => _onTimerReset(setData, exercise),
      onShowPostExerciseSheet: () => _showPostExerciseSheet(exercise),
      onShowPostMuscleGroupSheet: () => _showPostMuscleGroupSheet(mg),
      onShowExerciseSkipSheet: () => _showExerciseSkipSheet(exercise),
      onUnskipExercise: () => _unskipExercise(exercise),
      onAddSet: () => _addSet(exercise),
      onToggleSet: (setData, checked) => _onToggle(setData, checked, exercise),
      onShowSetSkipSheet: (setData) => _showSkipReasonSheet(setData, exercise),
      onDeleteSet: (setData) => _deleteSet(setData, exercise),
      onTogglePersistence: () => _togglePersistence(exercise),
      onReplace: canReplace ? () => _replaceExercise(exercise) : null,
      onAddExercise: () => _addExercise(after: exercise),
      onMoveUp: canMoveUp ? () => _moveExerciseUp(index) : null,
      onMoveDown: canMoveDown ? () => _moveExerciseDown(index) : null,
      onDeleteExercise: isNotStarted ? () => _deleteExercise(exercise) : null,
      onShowMovementHistorySheet: () => _showMovementHistorySheet(exercise),
      onWeightChanged: (setData, value) =>
          _propagateWeight(exercise, setData, value),
      onDistanceChanged: (setData, value) =>
          _propagateDistance(exercise, setData, value),
      onToggleAutoProgress: () => _toggleAutoProgress(exercise),
      onEditNote: () => _editNote(exercise),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initialText});
  final String initialText;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exercise Note'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Add a note…',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
