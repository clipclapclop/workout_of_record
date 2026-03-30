import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/tables/enums.dart';
import '../db/workout_data.dart';
import 'set_ui_state.dart';
import 'set_widget.dart';

enum _ExMenuAction { skipExercise, addSet, replace, togglePersistent, addExercise, moveUp, moveDown, deleteExercise, toggleAutoProgress, addNote }

/// A card for a single exercise within a workout.
class ExerciseWidget extends StatelessWidget {
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
    required this.setStates,
    required this.onTimerReset,
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
    this.onAddExercise,
    this.onMoveUp,
    this.onMoveDown,
    this.onDeleteExercise,
    required this.onShowMovementHistorySheet,
    required this.onWeightChanged,
    required this.onDistanceChanged,
    this.onToggleAutoProgress,
    required this.onEditNote,
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
  final Map<int, SetUiState> setStates;

  final VoidCallback onTimerReset;
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
  final VoidCallback? onAddExercise;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDeleteExercise;
  final VoidCallback onShowMovementHistorySheet;
  final void Function(SetData setData, String value) onWeightChanged;
  final void Function(SetData setData, String value) onDistanceChanged;
  final VoidCallback? onToggleAutoProgress;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final movement = exercise.movement;

    // ── Header trailing widget ─────────────────────────────────────────────
    final Widget headerTrailing;
    if (isExSkipped) {
      headerTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onUnskipExercise,
            child: const Text('Unskip'),
          ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _ExMenuAction.replace) {
                onReplace();
              } else if (action == _ExMenuAction.moveUp) {
                onMoveUp?.call();
              } else if (action == _ExMenuAction.moveDown) {
                onMoveDown?.call();
              } else if (action == _ExMenuAction.toggleAutoProgress) {
                onToggleAutoProgress?.call();
              } else if (action == _ExMenuAction.addNote) {
                onEditNote();
              } else {
                onTogglePersistence();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ExMenuAction.replace,
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Replace'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (onMoveUp != null)
                const PopupMenuItem(
                  value: _ExMenuAction.moveUp,
                  child: ListTile(
                    leading: Icon(Icons.arrow_upward),
                    title: Text('Move Up'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onMoveDown != null)
                const PopupMenuItem(
                  value: _ExMenuAction.moveDown,
                  child: ListTile(
                    leading: Icon(Icons.arrow_downward),
                    title: Text('Move Down'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: _ExMenuAction.addNote,
                child: ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text(movement.note1 != null ? 'Edit Note' : 'Add Note'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _ExMenuAction.togglePersistent,
                child: Row(
                  children: [
                    IgnorePointer(
                      child: Checkbox(
                        value: persistence == Persistence.persistent,
                        onChanged: (_) {},
                      ),
                    ),
                    const Text('Carry forward'),
                  ],
                ),
              ),
              if (onToggleAutoProgress != null)
                PopupMenuItem(
                  value: _ExMenuAction.toggleAutoProgress,
                  child: Row(
                    children: [
                      IgnorePointer(
                        child: Checkbox(
                          value: exercise.completed.autoProgress,
                          onChanged: (_) {},
                        ),
                      ),
                      const Text('Auto-progress'),
                    ],
                  ),
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
              onPressed: onShowPostExerciseSheet,
              child: const Text('Rate joint pain'),
            ),
          PopupMenuButton<_ExMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _ExMenuAction.skipExercise) {
                onShowExerciseSkipSheet();
              } else if (action == _ExMenuAction.addSet) {
                onAddSet();
              } else if (action == _ExMenuAction.replace) {
                onReplace();
              } else if (action == _ExMenuAction.addExercise) {
                onAddExercise?.call();
              } else if (action == _ExMenuAction.moveUp) {
                onMoveUp?.call();
              } else if (action == _ExMenuAction.moveDown) {
                onMoveDown?.call();
              } else if (action == _ExMenuAction.deleteExercise) {
                onDeleteExercise?.call();
              } else if (action == _ExMenuAction.toggleAutoProgress) {
                onToggleAutoProgress?.call();
              } else if (action == _ExMenuAction.addNote) {
                onEditNote();
              } else {
                onTogglePersistence();
              }
            },
            itemBuilder: (_) {
              final isExCompleted = allSetsDone && !showPostExReopen;
              return [
                PopupMenuItem(
                  value: _ExMenuAction.skipExercise,
                  enabled: !anySetChecked && !isExLocked,
                  child: const ListTile(
                    leading: Icon(Icons.block),
                    title: Text('Skip Exercise'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: _ExMenuAction.addSet,
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Add Set'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: _ExMenuAction.replace,
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Replace'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!isExCompleted && onAddExercise != null)
                  const PopupMenuItem(
                    value: _ExMenuAction.addExercise,
                    child: ListTile(
                      leading: Icon(Icons.fitness_center),
                      title: Text('Add Exercise'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (onMoveUp != null)
                  const PopupMenuItem(
                    value: _ExMenuAction.moveUp,
                    child: ListTile(
                      leading: Icon(Icons.arrow_upward),
                      title: Text('Move Up'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (onMoveDown != null)
                  const PopupMenuItem(
                    value: _ExMenuAction.moveDown,
                    child: ListTile(
                      leading: Icon(Icons.arrow_downward),
                      title: Text('Move Down'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (onDeleteExercise != null)
                  const PopupMenuItem(
                    value: _ExMenuAction.deleteExercise,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete Exercise'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                PopupMenuItem(
                  value: _ExMenuAction.addNote,
                  child: ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(movement.note1 != null ? 'Edit Note' : 'Add Note'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _ExMenuAction.togglePersistent,
                  child: Row(
                    children: [
                      IgnorePointer(
                        child: Checkbox(
                          value: persistence == Persistence.persistent,
                          onChanged: (_) {},
                        ),
                      ),
                      const Text('Carry forward'),
                    ],
                  ),
                ),
                if (onToggleAutoProgress != null)
                  PopupMenuItem(
                    value: _ExMenuAction.toggleAutoProgress,
                    child: Row(
                      children: [
                        IgnorePointer(
                          child: Checkbox(
                            value: exercise.completed.autoProgress,
                            onChanged: (_) {},
                          ),
                        ),
                        const Text('Auto-progress'),
                      ],
                    ),
                  ),
              ];
            },
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
            onPressed: onShowMovementHistorySheet,
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
          isLastSet: i == exercise.sets.length - 1,
          isExSkipped: isExSkipped,
          isLocked: isExLocked ||
              (i > 0 &&
                  !(setStates[exercise.sets[i - 1].completed.id]
                          ?.isChecked ??
                      false)),
          isChecked:
              setStates[exercise.sets[i].completed.id]?.isChecked ?? false,
          isSkipped:
              setStates[exercise.sets[i].completed.id]?.isSkipped ?? false,
          state: setStates[exercise.sets[i].completed.id]!,
          onTimerReset: onTimerReset,
          onToggle: (checked) => onToggleSet(exercise.sets[i], checked),
          onSkip: () => onShowSetSkipSheet(exercise.sets[i]),
          onDelete: () => onDeleteSet(exercise.sets[i]),
          onWeightChanged: movement.isRequiredWeight
              ? (v) => onWeightChanged(exercise.sets[i], v)
              : null,
          onDistanceChanged: movement.isRequiredDistance
              ? (v) => onDistanceChanged(exercise.sets[i], v)
              : null,
        ),
      ],
    ];

    // ── Card body ──────────────────────────────────────────────────────────
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (movement.note1 != null)
          GestureDetector(
            onTap: onEditNote,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB8860B).withValues(alpha: 0.25),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFDAA520),
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFDAA520)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      movement.note1!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFDAA520),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...setRows,
        if (showPostMgReopen)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: TextButton.icon(
              onPressed: onShowPostMuscleGroupSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text('Rate $mgLabel'),
            ),
          ),
      ],
    );

    if (isExSkipped) {
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
