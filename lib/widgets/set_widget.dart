import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/workout_data.dart';
import 'set_ui_state.dart';

enum _SetMenuAction { skip, delete }

/// A single set row within an exercise.
///
/// Owns [_hasResetTimer] so that the first interaction on this set
/// triggers a timer reset exactly once. The flag is cleared automatically
/// when [isChecked] transitions back to false (i.e. the set is unchecked).
class SetWidget extends StatefulWidget {
  const SetWidget({
    super.key,
    required this.setData,
    required this.movement,
    required this.setNum,
    required this.isExSkipped,
    required this.isLocked,
    required this.isChecked,
    required this.isSkipped,
    required this.state,
    required this.onTimerReset,
    required this.onToggle,
    required this.onSkip,
    required this.onDelete,
    this.onWeightChanged,
    this.onDistanceChanged,
  });

  final SetData setData;
  final Movement movement;
  final int setNum;
  final bool isExSkipped;
  final bool isLocked;
  /// Passed explicitly (in addition to [state]) so [didUpdateWidget] can
  /// detect the true→false transition and clear [_hasResetTimer].
  final bool isChecked;
  final bool isSkipped;
  final SetUiState state;
  /// Called once per set on first interaction (input tap/change or checkbox
  /// check). ExerciseWidget resets + restarts the timer in response.
  final VoidCallback onTimerReset;
  final Future<void> Function(bool checked) onToggle;
  final Future<void> Function() onSkip;
  final Future<void> Function() onDelete;
  /// Propagates weight to subsequent unchecked sets. Null if not applicable.
  final void Function(String)? onWeightChanged;
  /// Propagates distance to subsequent unchecked sets. Null if not applicable.
  final void Function(String)? onDistanceChanged;

  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget> {
  bool _hasResetTimer = false;

  @override
  void didUpdateWidget(SetWidget old) {
    super.didUpdateWidget(old);
    // When the set is unchecked, re-arm the one-shot timer reset.
    if (old.isChecked && !widget.isChecked) {
      _hasResetTimer = false;
    }
  }

  void _maybeResetTimer() {
    if (!_hasResetTimer) {
      _hasResetTimer = true;
      widget.onTimerReset();
    }
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    bool isInt = false,
    required bool enabled,
    void Function(String)? onChanged,
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
        onTap: _maybeResetTimer,
        onChanged: (v) {
          setState(() {});
          _maybeResetTimer();
          onChanged?.call(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final movement = widget.movement;
    final canCheck = state.canCheck(movement);
    final isChecked = widget.isChecked;
    final isSkipped = widget.isSkipped;
    final isLocked = widget.isLocked;
    final isExSkipped = widget.isExSkipped;

    Color? rowColor;
    if (isSkipped) {
      rowColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.12);
    } else if (isChecked) {
      rowColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    }

    return Container(
      decoration: rowColor != null
          ? BoxDecoration(
              color: rowColor,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'Set ${widget.setNum}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (movement.isRequiredWeight) ...[
            const SizedBox(width: 8),
            _inputField(
              state.weightCtrl,
              AppPreferences.getUnitsMetric() ? 'kg' : 'lbs',
              enabled: !isChecked && !isLocked,
              onChanged: widget.onWeightChanged,
            ),
          ],
          if (movement.isRequiredReps) ...[
            const SizedBox(width: 8),
            _inputField(
              state.repsCtrl,
              'Reps',
              isInt: true,
              enabled: !isChecked && !isLocked,
            ),
          ],
          if (movement.isRequiredDistance) ...[
            const SizedBox(width: 8),
            _inputField(
              state.distanceCtrl,
              AppPreferences.getUnitsMetric() ? 'km' : 'mi',
              enabled: !isChecked && !isLocked,
              onChanged: widget.onDistanceChanged,
            ),
          ],
          if (movement.isRequiredTime) ...[
            const SizedBox(width: 8),
            _inputField(
              state.timeCtrl,
              'Time',
              enabled: !isChecked && !isLocked,
            ),
          ],
          const SizedBox(width: 8),
          Checkbox(
            value: isChecked,
            onChanged: isExSkipped || isLocked
                ? null
                : (canCheck || isChecked)
                    ? (v) {
                        if (v == true) _maybeResetTimer();
                        widget.onToggle(v!);
                      }
                    : null,
          ),
          PopupMenuButton<_SetMenuAction>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == _SetMenuAction.skip) {
                widget.onSkip();
              } else if (action == _SetMenuAction.delete) {
                widget.onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _SetMenuAction.skip,
                enabled: !isChecked && !isExSkipped && !isLocked,
                child: const Text('Skip'),
              ),
              if (widget.setData.planned == null)
                PopupMenuItem(
                  value: _SetMenuAction.delete,
                  enabled: !isChecked,
                  child: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
