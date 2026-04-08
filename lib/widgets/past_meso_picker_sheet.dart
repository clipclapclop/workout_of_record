import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/template_data.dart';

/// Shows a bottom-sheet picker that lets the user choose a mesocycle and week
/// to copy into the template builder.  Returns the extracted [MesoTemplateData]
/// or `null` if the sheet was dismissed.
Future<MesoTemplateData?> showPastMesoPickerSheet(BuildContext context) {
  return showModalBottomSheet<MesoTemplateData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _PastMesoPickerSheet(),
  );
}

class _PastMesoPickerSheet extends StatefulWidget {
  const _PastMesoPickerSheet();

  @override
  State<_PastMesoPickerSheet> createState() => _PastMesoPickerSheetState();
}

class _PastMesoPickerSheetState extends State<_PastMesoPickerSheet> {
  late Future<List<MesocycleWeekSummary>> _future;
  bool _loading = false; // true while extracting a week

  @override
  void initState() {
    super.initState();
    _future = db.getMesocyclesWithCompletedWeeks();
  }

  Future<void> _onWeekTap(int weekId) async {
    setState(() => _loading = true);
    try {
      final data = await db.getMesoTemplateDataFromWeek(weekId);
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
              child: Text(
                'Copy from Past Mesocycle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: FutureBuilder<List<MesocycleWeekSummary>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final summaries = snap.data!;
                  if (summaries.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No past mesocycles with completed workouts.',
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
    final inProgress = meso.completedAt == null;

    return ExpansionTile(
      title: Text(meso.name),
      subtitle: Row(
        children: [
          Text(_formatDate(meso.createdAt),
              style: Theme.of(context).textTheme.bodySmall),
          if (inProgress) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'In Progress',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ],
      ),
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
