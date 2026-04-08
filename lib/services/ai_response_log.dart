import '../db/planning.dart';

/// A single AI recommendation request/response pair.
class AiLogEntry {
  final DateTime timestamp;
  final String movementName;
  final String model;
  final String systemPrompt;
  final String userMessage;
  final String? rawResponse;
  final bool parseSuccess;
  final String? parseError;
  final List<PlannedSetValues>? aiResult;
  final List<PlannedSetValues> heuristicResult;
  final String? error;

  const AiLogEntry({
    required this.timestamp,
    required this.movementName,
    required this.model,
    required this.systemPrompt,
    required this.userMessage,
    this.rawResponse,
    required this.parseSuccess,
    this.parseError,
    this.aiResult,
    required this.heuristicResult,
    this.error,
  });
}

/// In-memory log of AI recommendation attempts. Session-only.
class AiResponseLog {
  AiResponseLog._();
  static final instance = AiResponseLog._();

  static const maxEntries = 50;

  final List<AiLogEntry> _entries = [];

  List<AiLogEntry> get entries => List.unmodifiable(_entries);

  void add(AiLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  void clear() => _entries.clear();
}
