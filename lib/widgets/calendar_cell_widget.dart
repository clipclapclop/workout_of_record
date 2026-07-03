import 'package:flutter/material.dart';

import '../db/calendar_data.dart';
import '../db/tables/enums.dart';

/// A single cell in a calendar grid representing one workout.
///
/// Renders with status-based colors and icons:
/// - Current workout (matching [highlightId]): error container + play arrow
/// - Completed: green + checkmark
/// - Skipped: red + skip icon
/// - Future / empty: subtle gray, no icon
class CalendarCellWidget extends StatelessWidget {
  const CalendarCellWidget({
    super.key,
    required this.cell,
    required this.width,
    required this.height,
    this.highlightId,
    this.onTap,
  });

  final CalendarCell cell;
  final double width;
  final double height;

  /// If non-null, a completed-workout ID that should be highlighted as
  /// "currently active" (red play-arrow style).  Pass null in contexts
  /// where there is no active workout (e.g. history screen).
  final int? highlightId;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cw = cell.completedWorkout;
    final isCurrent =
        highlightId != null && cw != null && cw.id == highlightId;
    final isDone = cw != null &&
        cw.completedAt != null &&
        cw.status == WorkoutStatus.completed;
    final isSkipped = cw != null && cw.status == WorkoutStatus.skipped;

    final cs = Theme.of(context).colorScheme;
    final Color bgColor;
    final Color textColor;
    final IconData? icon;
    final Color? iconColor;

    if (isCurrent) {
      bgColor = cs.errorContainer;
      textColor = cs.onErrorContainer;
      icon = Icons.play_arrow;
      iconColor = cs.error;
    } else if (isDone) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green.shade800;
      icon = Icons.check;
      iconColor = Colors.green.shade700;
    } else if (isSkipped) {
      bgColor = cs.errorContainer.withValues(alpha: 0.5);
      textColor = cs.onErrorContainer;
      icon = Icons.skip_next;
      iconColor = cs.error;
    } else {
      // Future (materialized not-yet-started, or template-only)
      bgColor = cs.surfaceContainerHighest;
      textColor = cs.onSurfaceVariant;
      icon = null;
      iconColor = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 16, color: iconColor),
              if (icon != null) const SizedBox(height: 2),
              Text(
                cell.workoutName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single week column in a calendar grid: header label + cells.
class CalendarWeekColumn extends StatelessWidget {
  const CalendarWeekColumn({
    super.key,
    required this.week,
    required this.maxRows,
    required this.cellBuilder,
    this.cellWidth = 96.0,
    this.cellHeight = 72.0,
    this.headerHeight = 36.0,
  });

  final CalendarWeek week;

  /// Maximum number of workout rows across all weeks in the calendar,
  /// so shorter weeks can be padded with empty space.
  final int maxRows;

  /// Builds the widget for a single cell. Consumers supply this to wire
  /// up their own tap behaviour.
  final Widget Function(CalendarCell cell, double width, double height)
      cellBuilder;

  final double cellWidth;
  final double cellHeight;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final label =
        week.goal == WeekGoal.deload ? 'DL' : 'Wk ${week.weekNumber}';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        children: [
          SizedBox(
            width: cellWidth,
            height: headerHeight,
            child: Center(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          for (var i = 0; i < maxRows; i++)
            i < week.cells.length
                ? cellBuilder(week.cells[i], cellWidth, cellHeight)
                : SizedBox(width: cellWidth, height: cellHeight + 6),
        ],
      ),
    );
  }
}
