import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import 'rest_timer_controller.dart';
import 'rest_timer_widget.dart';
import 'set_ui_state.dart';
import 'set_widget.dart';

enum _ExMenuAction { skipExercise, addSet, replace, togglePersistent }

/// A card for a single exercise within a workout.
///
/// Owns a [RestTimerController] for its rest timer. The timer auto-starts
/// when [isActive] flips true and stops when [allSetsDone] becomes true
/// (i.e. when the post-exercise sheet fires) or the exercise is skipped.
///
/// Each child [SetWidget] calls [_onTimerReset] on its first interaction,
/// which resets and restarts the timer for that set.
class ExerciseWidget extends StatefulWidget {
  const ExerciseWidget({
    super.key,
    required this.exercise,
    required this.isActive,
    required this.isExSkipped,
    required this.isExLocked,
    required this.allSetsDone,
    required this.showPostExReopen,
    required this.anySetChecked,
    required this.showPostMgReopen,
    required this.mgLabel,
    required this.persistence,
    required this.timerEnabled,
    required this.workoutTimerOn,
    required this.timerDurationSeconds,
    required this.cueText,
    required this.setStates,
    required this.onToggleWorkoutTimer,
    required this.onShowPostExerciseSheet,
    required this.onShowPostMuscleGroupSheet,
    required this.onShowExerciseSkipSheet,
    required this.onUnskipExercise,
    required this.onAddSet,
    required this.onToggleSet,
    required this.onShowSetSkipSheet,
    required this.onDeleteSet,
    required this.onTogglePersistence,
    required this.onReplace,
    required this.onShowMovementHistorySheet,
    required this.onWeightChanged,
    required this.onDistanceChanged,
  });

  final ExerciseData exercise;
  final bool isActive;
  final bool isExSkipped;
  final bool isExLocked;
  final bool allSetsDone;
  final bool showPostExReopen;
  final bool anySetChecked;
  final bool showPostMgReopen;
  final String mgLabel;
  final Persistence persistence;
  final bool timerEnabled;
  final bool workoutTimerOn;
  final int timerDurationSeconds;
  final String? cueText;
  final Map<int, SetUiState> setStates;

  final VoidCallback onToggleWorkoutTimer;
  final Future<void> Function() onShowPostExerciseSheet;
  final Future<void> Function() onShowPostMuscleGroupSheet;
  final Future<void> Function() onShowExerciseSkipSheet;
  final Future<void> Function() onUnskipExercise;
  final Future<void> Function() onAddSet;
  final Future<void> Function(SetData setData, bool checked) onToggleSet;
  final Future<void> Function(SetData setData) onShowSetSkipSheet;
  final Future<void> Function(SetData setData) onDeleteSet;
  final VoidCallback onTogglePersistence;
  final VoidCallback onReplace;
  final VoidCallback onShowMovementHistorySheet;
  final void Function(SetData setData, String value) onWeightChanged;
  final void Function(SetData setData, String value) onDistanceChanged;

  @override
  State<ExerciseWidget> createState() => _ExerciseWidgetState();
}

class _ExerciseWidgetState extends State<ExerciseWidget> {
  late RestTimerController _timerController;

  bool get _timerRunnable =>
      widget.isActive &&
      !widget.isExSkipped &&
      !widget.allSetsDone &&
      widget.timerEnabled &&
      widget.workoutTimerOn &&
      widget.timerDurationSeconds > 0;

  bool get _showTimer =>
      widget.isActive &&
      !widget.isExSkipped &&
      widget.timerEnabled &&
      widget.workoutTimerOn &&
      widget.timerDurationSeconds > 0 &&
      !widget.allSetsDone;

  @override
  void initState() {
    super.initState();
    _timerController =
        RestTimerController(durationSeconds: widget.timerDurationSeconds);
    if (_timerRunnable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _timerController.start();
      });
    }
  }

  @override
  void didUpdateWidget(ExerciseWidget old) {
    super.didUpdateWidget(old);

    // Duration changed (e.g. movement rest setting updated).
    if (old.timerDurationSeconds != widget.timerDurationSeconds) {
      _timerController.setDuration(widget.timerDurationSeconds);
    }

    final wasRunnable = old.isActive &&
        !old.isExSkipped &&
        !old.allSetsDone &&
        old.timerDurationSeconds > 0;
    final isRunnable = widget.isActive &&
        !widget.isExSkipped &&
        !widget.allSetsDone &&
        widget.timerDurationSeconds > 0;

    // Exercise became active and ready — start the timer.
    if (!wasRunnable && isRunnable && widget.timerEnabled && widget.workoutTimerOn) {
      _timerController.start();
    }

    // Exercise became inactive, skipped, or all sets done — stop the timer.
    if (wasRunnable && !isRunnable) {
      _timerController.stop();
    }

    // Per-workout timer toggled off.
    if (old.workoutTimerOn && !widget.workoutTimerOn) {
      _timerController.stop();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  /// Called by a SetWidget on its first interaction. Resets and restarts the
  /// timer from the full duration.
  void _onTimerReset() {
    if (widget.timerDurationSeconds > 0 &&
        widget.timerEnabled &&
        widget.workoutTimerOn) {
      _timerController.reset();
      _timerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final movement = exercise.movement;

    // ── Header trailing widget ─────────────────────────────────────────────
    final Widget headerTrailing;
    if (widget.isExSkipped) {
      headerTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: widget.onUnskipExercise,
            child: const Text('Unskip'),
          ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _ExMenuAction.replace) {
                widget.onReplace();
              } else {
                widget.onTogglePersistence();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ExMenuAction.replace,
                child: Text('Replace'),
              ),
              PopupMenuItem(
                value: _ExMenuAction.togglePersistent,
                child: Text(widget.persistence == Persistence.persistent
                    ? "Don't carry forward"
                    : 'Carry forward'),
              ),
            ],
          ),
        ],
      );
    } else {
      headerTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showPostExReopen)
            TextButton(
              onPressed: widget.onShowPostExerciseSheet,
              child: const Text('Rate joint pain'),
            ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _ExMenuAction.skipExercise) {
                widget.onShowExerciseSkipSheet();
              } else if (action == _ExMenuAction.addSet) {
                widget.onAddSet();
              } else if (action == _ExMenuAction.replace) {
                widget.onReplace();
              } else {
                widget.onTogglePersistence();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ExMenuAction.skipExercise,
                enabled: !widget.anySetChecked && !widget.isExLocked,
                child: const Text('Skip Exercise'),
              ),
              const PopupMenuItem(
                value: _ExMenuAction.addSet,
                child: Text('Add Set'),
              ),
              const PopupMenuItem(
                value: _ExMenuAction.replace,
                child: Text('Replace'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ExMenuAction.togglePersistent,
                child: Text(widget.persistence == Persistence.persistent
                    ? "Don't carry forward"
                    : 'Carry forward'),
              ),
            ],
          ),
        ],
      );
    }

    // ── Header ─────────────────────────────────────────────────────────────
    final header = Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              movement.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (movement.link != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => launchUrl(
                Uri.parse(movement.link!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: widget.onShowMovementHistorySheet,
          ),
          headerTrailing,
        ],
      ),
    );

    // ── Set rows ───────────────────────────────────────────────────────────
    final setRows = [
      for (var i = 0; i < exercise.sets.length; i++) ...[
        SetWidget(
          key: ValueKey(exercise.sets[i].completed.id),
          setData: exercise.sets[i],
          movement: movement,
          setNum: i + 1,
          isExSkipped: widget.isExSkipped,
          isLocked: widget.isExLocked ||
              (i > 0 &&
                  !(widget.setStates[exercise.sets[i - 1].completed.id]
                          ?.isChecked ??
                      false)),
          isChecked:
              widget.setStates[exercise.sets[i].completed.id]?.isChecked ??
                  false,
          isSkipped:
              widget.setStates[exercise.sets[i].completed.id]?.isSkipped ??
                  false,
          state: widget.setStates[exercise.sets[i].completed.id]!,
          onTimerReset: _onTimerReset,
          onToggle: (checked) =>
              widget.onToggleSet(exercise.sets[i], checked),
          onSkip: () => widget.onShowSetSkipSheet(exercise.sets[i]),
          onDelete: () => widget.onDeleteSet(exercise.sets[i]),
          onWeightChanged: movement.isRequiredWeight
              ? (v) => widget.onWeightChanged(exercise.sets[i], v)
              : null,
          onDistanceChanged: movement.isRequiredDistance
              ? (v) => widget.onDistanceChanged(exercise.sets[i], v)
              : null,
        ),
      ],
    ];

    // ── Card body ──────────────────────────────────────────────────────────
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (_showTimer)
          RestTimerWidget(
            key: ValueKey('timer_${exercise.completed.id}'),
            controller: _timerController,
            cueText: widget.cueText,
          ),
        if (movement.note1 != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              movement.note1!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ...setRows,
        if (widget.showPostMgReopen)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: TextButton.icon(
              onPressed: widget.onShowPostMuscleGroupSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text('Rate ${widget.mgLabel}'),
            ),
          ),
      ],
    );

    if (widget.isExSkipped) {
      return Card(
        margin: const EdgeInsets.only(top: 8),
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          child: column,
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
        child: column,
      ),
    );
  }
}
