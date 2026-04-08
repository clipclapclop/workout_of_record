import 'package:flutter/material.dart';

import '../../db/planning.dart';
import '../../services/ai_response_log.dart';

class AiLogScreen extends StatefulWidget {
  const AiLogScreen({super.key});

  @override
  State<AiLogScreen> createState() => _AiLogScreenState();
}

class _AiLogScreenState extends State<AiLogScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = AiResponseLog.instance.entries;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Log'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear log',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear log?'),
                    content: const Text(
                        'This clears the in-memory session log. Exported files are not affected.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  AiResponseLog.instance.clear();
                  setState(() {});
                }
              },
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No AI requests this session.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _EntryTile(entry: entries[index]),
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final AiLogEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time =
        '${_pad(entry.timestamp.hour)}:${_pad(entry.timestamp.minute)}:${_pad(entry.timestamp.second)}';

    return ExpansionTile(
      leading: Icon(
        entry.parseSuccess ? Icons.check_circle : Icons.error,
        color: entry.parseSuccess
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
        size: 20,
      ),
      title: Text(entry.movementName),
      subtitle: Text(
        '$time  ·  ${entry.model}',
        style: theme.textTheme.bodySmall,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.error != null) ...[
                _label(theme, 'Error'),
                _body(theme, entry.error!, isError: true),
                const SizedBox(height: 12),
              ],
              if (entry.parseError != null) ...[
                _label(theme, 'Parse Error'),
                _body(theme, entry.parseError!, isError: true),
                const SizedBox(height: 12),
              ],
              _label(theme, 'System Prompt'),
              _body(theme, entry.systemPrompt),
              const SizedBox(height: 12),
              _label(theme, 'User Message'),
              _body(theme, entry.userMessage),
              const SizedBox(height: 12),
              if (entry.rawResponse != null) ...[
                _label(theme, 'Raw Response'),
                _body(theme, entry.rawResponse!),
                const SizedBox(height: 12),
              ],
              if (entry.aiResult != null) ...[
                _label(theme, 'AI Picked'),
                _setList(theme, entry.aiResult!),
                const SizedBox(height: 12),
              ],
              _label(theme, 'Heuristic Would Have Given'),
              _setList(theme, entry.heuristicResult),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _body(ThemeData theme, String text, {bool isError = false}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: SelectableText(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
        ),
      );

  Widget _setList(ThemeData theme, List<PlannedSetValues> sets) {
    final lines = <String>[];
    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];
      final parts = <String>[];
      if (s.reps != null) parts.add('${s.reps} reps');
      if (s.weight != null) parts.add('${s.weight}');
      if (s.time != null) parts.add('${s.time}s');
      lines.add('Set ${i + 1}: ${parts.isEmpty ? '(empty)' : parts.join(' x ')}');
    }
    return _body(theme, lines.join('\n'));
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
