import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/template_data.dart';
import 'load_failure_view.dart';

/// Lets the user choose a fully completed week from a completed mesocycle.
Future<PastWeekTemplateData?> showPastMesoPickerSheet(
  BuildContext context, {
  Future<List<MesocycleWeekSummary>> Function()? loadSummaries,
  Future<PastWeekTemplateData> Function(int)? loadWeek,
}) {
  return showModalBottomSheet<PastWeekTemplateData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PastMesoPickerSheet(
      loadSummaries: loadSummaries ?? db.getMesocyclesWithCompletedWeeks,
      loadWeek: loadWeek ?? db.getMesoTemplateDataFromWeek,
    ),
  );
}

class _PastMesoPickerSheet extends StatefulWidget {
  const _PastMesoPickerSheet({
    required this.loadSummaries,
    required this.loadWeek,
  });

  final Future<List<MesocycleWeekSummary>> Function() loadSummaries;
  final Future<PastWeekTemplateData> Function(int) loadWeek;

  @override
  State<_PastMesoPickerSheet> createState() => _PastMesoPickerSheetState();
}

class _PastMesoPickerSheetState extends State<_PastMesoPickerSheet> {
  Future<List<MesocycleWeekSummary>>? _future;
  bool _loading = false; // true while extracting a week

  void _retry() {
    setState(() => _future = null);
  }

  Future<void> _onWeekTap(int weekId) async {
    setState(() => _loading = true);
    try {
      final data = await widget.loadWeek(weekId);
      if (!mounted) return;
      Navigator.pop(context, data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract exercises.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future ??= Future.sync(widget.loadSummaries);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    'Use a Week from a Past Mesocycle',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a completed week to review before deciding whether to use or edit it.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: FutureBuilder<List<MesocycleWeekSummary>>(
                future: future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return LoadFailureView(
                      message: 'Couldn’t load past mesocycles.',
                      onRetry: _retry,
                      onClose: () => Navigator.pop(context),
                    );
                  }
                  final summaries = snap.data!;
                  if (summaries.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No completed mesocycles with completed weeks.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom),
                    itemCount: summaries.length,
                    itemBuilder: (ctx, i) =>
                        _MesoTile(summary: summaries[i], onWeekTap: _onWeekTap),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Mesocycle expansion tile ──────────────────────────────────────────────────

class _MesoTile extends StatelessWidget {
  const _MesoTile({required this.summary, required this.onWeekTap});

  final MesocycleWeekSummary summary;
  final ValueChanged<int> onWeekTap;

  @override
  Widget build(BuildContext context) {
    final meso = summary.mesocycle;
    return ExpansionTile(
      title: Text(meso.name),
      subtitle: Text(_formatDate(meso.createdAt),
          style: Theme.of(context).textTheme.bodySmall),
      children: summary.weeks.map((ws) {
        final goalLabel =
            ws.week.goal == WeekGoal.deload ? 'Deload' : 'Hard';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: Text('Week ${ws.week.weekNumber} ($goalLabel)'),
          subtitle: Text(
              '${ws.completedWorkoutCount}/${ws.totalWorkoutCount} workouts completed'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onWeekTap(ws.week.id),
        );
      }).toList(),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
