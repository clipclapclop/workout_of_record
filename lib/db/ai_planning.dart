import 'dart:convert';

import '../app_preferences.dart';
import '../services/ai_context_builder.dart';
import '../services/ai_service.dart';
import 'app_database.dart';
import 'planning.dart';
import 'tables/enums.dart';

/// Represents the set of options the AI can choose from for one exercise.
class ExerciseOptions {
  final String movementName;
  final MuscleGroup muscleGroup;
  final List<int> setCountOptions; // e.g. [3, 4]
  final List<SetOption> perSetOptions; // one per prior set

  const ExerciseOptions({
    required this.movementName,
    required this.muscleGroup,
    required this.setCountOptions,
    required this.perSetOptions,
  });

  Map<String, dynamic> toJson() => {
        'movement': movementName,
        'muscleGroup': muscleGroup.name,
        'setCountOptions': setCountOptions,
        'sets': [for (final s in perSetOptions) s.toJson()],
      };
}

/// Options for a single set (reps and weight choices).
class SetOption {
  final int setIndex;
  final List<int?> repsOptions; // e.g. [9, 10, 11] or empty if not applicable
  final List<double?> weightOptions; // e.g. [92.5, 95.0, 97.5]

  const SetOption({
    required this.setIndex,
    required this.repsOptions,
    required this.weightOptions,
  });

  Map<String, dynamic> toJson() => {
        'setIndex': setIndex,
        if (repsOptions.isNotEmpty)
          'repsOptions': repsOptions,
        if (weightOptions.isNotEmpty)
          'weightOptions': weightOptions,
      };
}

/// The AI's choice for one exercise.
class ExercisePick {
  final int setCount;
  final List<SetPick> sets;

  const ExercisePick({required this.setCount, required this.sets});
}

/// The AI's choice for one set.
class SetPick {
  final int? reps;
  final double? weight;

  const SetPick({this.reps, this.weight});
}

/// Result of an AI recommendation attempt.
class AiRecommendationResult {
  final List<PlannedSetValues> values;
  final bool usedAi;
  final String? error;

  const AiRecommendationResult({
    required this.values,
    required this.usedAi,
    this.error,
  });
}

/// Builds the constrained option space and asks the AI to pick.
/// Falls back to [computeHeuristic] on any failure.
/// Returns [AiRecommendationResult] with metadata about whether AI was used.
Future<AiRecommendationResult> computeAiRecommendation({
  required List<CompletedSet> priorSets,
  required WeekGoal weekGoal,
  required Movement movement,
  required int targetCount,
  required int mesocycleId,
  required int weekNumber,
  required String workoutName,
  int? workoutId,
  bool autoProgress = false,
}) async {
  List<PlannedSetValues> fallback() => computeHeuristic(
      priorSets, weekGoal, movement, targetCount,
      autoProgress: autoProgress);

  // Quick guard: if AI is disabled or no API key, fall back immediately.
  try {
    if (!AppPreferences.getAiEnabled()) {
      return AiRecommendationResult(values: fallback(), usedAi: false);
    }
  } catch (_) {
    // Prefs not initialized (e.g. in tests) — fall back.
    return AiRecommendationResult(values: fallback(), usedAi: false);
  }

  try {
    final options = _buildOptions(priorSets, weekGoal, movement, targetCount);
    final context = await AiContextBuilder.forRecommendation(
      mesocycleId: mesocycleId,
      weekNumber: weekNumber,
      weekGoal: weekGoal,
      workoutName: workoutName,
      workoutId: workoutId,
    );

    final systemPrompt = AppPreferences.getAiRecommendationPrompt();

    final userMessage = _buildUserMessage(options, context);

    final response = await AiService.chatCompletion([
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ]);

    final pick = _parseResponse(response, options);
    final values = _pickToPlannedValues(pick, options, priorSets, movement);
    return AiRecommendationResult(values: values, usedAi: true);
  } catch (e) {
    // Any failure → fall back to heuristic.
    return AiRecommendationResult(
      values: fallback(),
      usedAi: false,
      error: e.toString(),
    );
  }
}

// ── Option building ─────────────────────────────────────────────────────────

ExerciseOptions _buildOptions(
  List<CompletedSet> priorSets,
  WeekGoal weekGoal,
  Movement movement,
  int targetCount,
) {
  // Set count options: same as last week, or +1 (only on hard weeks).
  final setCountOptions = <int>[targetCount];
  if (weekGoal == WeekGoal.hard && targetCount > 0) {
    setCountOptions.add(targetCount + 1);
  }

  final delta = movement.weightDelta ?? 5.0;

  final perSetOptions = <SetOption>[];
  final setCount = priorSets.length > targetCount ? targetCount : priorSets.length;
  for (var i = 0; i < setCount; i++) {
    final s = priorSets[i];

    // Reps options
    final repsOptions = <int?>[];
    if (s.reps != null) {
      if (s.reps! > 1) repsOptions.add(s.reps! - 1);
      repsOptions.add(s.reps!);
      repsOptions.add(s.reps! + 1);
    }

    // Weight options
    final weightOptions = <double?>[];
    if (s.weight != null) {
      final lower = s.weight! - delta;
      if (lower >= (movement.minWeight ?? 0)) weightOptions.add(lower);
      weightOptions.add(s.weight!);
      weightOptions.add(s.weight! + delta);
    }

    perSetOptions.add(SetOption(
      setIndex: i,
      repsOptions: repsOptions,
      weightOptions: weightOptions,
    ));
  }

  return ExerciseOptions(
    movementName: movement.name,
    muscleGroup: movement.muscleGroup,
    setCountOptions: setCountOptions,
    perSetOptions: perSetOptions,
  );
}

String _buildUserMessage(ExerciseOptions options, String historyContext) {
  final buf = StringBuffer();
  buf.writeln(historyContext);
  buf.writeln('## Exercise to Plan: ${options.movementName} (${options.muscleGroup.name})');
  buf.writeln();

  // Show last week's numbers for reference.
  if (options.perSetOptions.isNotEmpty) {
    buf.writeln('Last week they did ${options.perSetOptions.length} sets:');
    for (final s in options.perSetOptions) {
      final parts = <String>[];
      // The middle option is "same as last week".
      if (s.repsOptions.length >= 2) parts.add('${s.repsOptions[s.repsOptions.length ~/ 2]} reps');
      if (s.weightOptions.length >= 2) parts.add('${s.weightOptions[s.weightOptions.length ~/ 2]}');
      buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' x ')}');
    }
    buf.writeln();
  }

  buf.writeln('Available options (based on equipment increments):');
  buf.writeln('  Set count: ${options.setCountOptions.join(' or ')}');
  for (final s in options.perSetOptions) {
    final parts = <String>[];
    if (s.repsOptions.isNotEmpty) parts.add('reps: ${s.repsOptions.join(", ")}');
    if (s.weightOptions.isNotEmpty) parts.add('weight: ${s.weightOptions.join(", ")}');
    buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' | ')}');
  }
  buf.writeln();

  buf.writeln('Respond with this JSON (choose from the available options):');
  buf.writeln('{"setCount": N, "sets": [{"setIndex": 0, "reps": N, "weight": N}, ...]}');
  buf.writeln('The "sets" array must have exactly "setCount" entries.');
  buf.writeln('If you pick a setCount higher than the number of listed sets, repeat the last set\'s values for the extra sets.');

  return buf.toString();
}

// ── Response parsing ────────────────────────────────────────────────────────

ExercisePick _parseResponse(String response, ExerciseOptions options) {
  // Extract JSON from response (may be wrapped in markdown code blocks).
  var jsonStr = response.trim();
  final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
  if (jsonMatch != null) {
    jsonStr = jsonMatch.group(1)!.trim();
  }

  final json = jsonDecode(jsonStr) as Map<String, dynamic>;

  final setCount = json['setCount'] as int;
  // Validate setCount is one of the options.
  if (!options.setCountOptions.contains(setCount)) {
    throw FormatException('Invalid setCount: $setCount');
  }

  final setsJson = json['sets'] as List<dynamic>;
  final sets = <SetPick>[];
  for (final s in setsJson) {
    final m = s as Map<String, dynamic>;
    sets.add(SetPick(
      reps: m['reps'] as int?,
      weight: (m['weight'] as num?)?.toDouble(),
    ));
  }

  return ExercisePick(setCount: setCount, sets: sets);
}

List<PlannedSetValues> _pickToPlannedValues(
  ExercisePick pick,
  ExerciseOptions options,
  List<CompletedSet> priorSets,
  Movement movement,
) {
  return List.generate(pick.setCount, (i) {
    if (i < pick.sets.length) {
      return PlannedSetValues(
        reps: pick.sets[i].reps,
        weight: pick.sets[i].weight,
        time: i < priorSets.length ? priorSets[i].time : null,
      );
    }
    // Extra sets beyond what the AI specified: use the last specified set.
    if (pick.sets.isNotEmpty) {
      final last = pick.sets.last;
      return PlannedSetValues(
        reps: last.reps,
        weight: last.weight,
        time: priorSets.isNotEmpty ? priorSets.last.time : null,
      );
    }
    return const PlannedSetValues();
  });
}
