import 'dart:convert';
import 'dart:typed_data';

import '../app_preferences.dart';
import '../db/planning.dart';
import 'ai_response_log.dart';
import 'saf_service.dart';

/// Writes AI log entries to markdown files in the user's chosen SAF folder.
class AiLogWriter {
  AiLogWriter._();

  /// Writes [entry] as a markdown section to `ai_log_YYYY-MM-DD.md`.
  /// No-op if logging is disabled or no folder is configured.
  static Future<void> writeEntry(AiLogEntry entry) async {
    try {
      if (!AppPreferences.getAiLoggingEnabled()) return;
      final folder = AppPreferences.getAiLogDirectoryPath();
      if (folder == null) return;

      final md = _formatEntry(entry);
      final date = entry.timestamp;
      final fileName =
          'ai_log_${date.year}-${_pad(date.month)}-${_pad(date.day)}.md';

      await SafService.appendToFile(
        folder,
        fileName,
        Uint8List.fromList(utf8.encode(md)),
      );
    } catch (_) {
      // Fire-and-forget — don't block the recommendation flow.
    }
  }

  static String _formatEntry(AiLogEntry entry) {
    final buf = StringBuffer();
    final time =
        '${_pad(entry.timestamp.hour)}:${_pad(entry.timestamp.minute)}:${_pad(entry.timestamp.second)}';
    final status = entry.parseSuccess ? 'Success' : 'Failed';

    buf.writeln('## ${entry.movementName} -- $time -- ${entry.model}');
    buf.writeln('**Status**: $status');
    if (entry.error != null) buf.writeln('**Error**: ${entry.error}');
    buf.writeln();

    buf.writeln('### System Prompt');
    buf.writeln(entry.systemPrompt);
    buf.writeln();

    buf.writeln('### User Message');
    buf.writeln(entry.userMessage);
    buf.writeln();

    if (entry.rawResponse != null) {
      buf.writeln('### AI Response');
      buf.writeln('```json');
      buf.writeln(entry.rawResponse);
      buf.writeln('```');
      buf.writeln();
    }

    if (entry.parseError != null) {
      buf.writeln('### Parse Error');
      buf.writeln(entry.parseError);
      buf.writeln();
    }

    if (entry.aiResult != null) {
      buf.writeln('### AI Picked');
      _appendSetValues(buf, entry.aiResult!);
      buf.writeln();
    }

    buf.writeln('### Heuristic Would Have Given');
    _appendSetValues(buf, entry.heuristicResult);
    buf.writeln();

    buf.writeln('---');
    buf.writeln();

    return buf.toString();
  }

  static void _appendSetValues(StringBuffer buf, List<PlannedSetValues> sets) {
    for (var i = 0; i < sets.length; i++) {
      final s = sets[i];
      final parts = <String>[];
      if (s.reps != null) parts.add('${s.reps} reps');
      if (s.weight != null) parts.add('${s.weight}');
      if (s.time != null) parts.add('${s.time}s');
      buf.writeln('Set ${i + 1}: ${parts.isEmpty ? '(empty)' : parts.join(' x ')}');
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
