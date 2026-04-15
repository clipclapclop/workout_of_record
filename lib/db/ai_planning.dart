import 'dart:convert';

import '../app_preferences.dart';
import '../services/ai_context_builder.dart';
import '../services/ai_log_writer.dart';
import '../services/ai_response_log.dart';
import '../services/ai_service.dart';
import 'app_database.dart';
import 'planning.dart';
import 'tables/enums.dart';

/// Appends user-authored notes to a system prompt, if any are set.
String _withUserNotes(String basePrompt) {
  final notes = AppPreferences.getAiUserNotes().trim();
  if (notes.isEmpty) return basePrompt;
  return '$basePrompt\n\nAdditional user notes:\n$notes';
}

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
        if (repsOptions.isNotEmpty) 'repsOptions': repsOptions,
        if (weightOptions.isNotEmpty) 'weightOptions': weightOptions,
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

/// One exercise's inputs for a batch AI recommendation call.
class BatchExerciseInput {
  final Movement movement;
  final List<CompletedSet> priorSets;
  final int targetCount;

  const BatchExerciseInput({
    required this.movement,
    required this.priorSets,
    required this.targetCount,
  });
}

/// Data for the test harness: the inputs that _resolvePlannedSets would have
/// used for one exercise, plus what actually happened.
class TestHarnessExerciseData {
  final Movement movement;
  final List<CompletedSet> priorSets; // prior week non-skipped
  final int targetCount; // prior week total set count
  final WeekGoal weekGoal;
  final int mesocycleId;
  final int weekNumber;
  final String workoutName;
  final int? workoutId;
  final List<CompletedSet> actualSets; // what really happened
  final bool autoProgress;

  const TestHarnessExerciseData({
    required this.movement,
    required this.priorSets,
    required this.targetCount,
    required this.weekGoal,
    required this.mesocycleId,
    required this.weekNumber,
    required this.workoutName,
    this.workoutId,
    required this.actualSets,
    required this.autoProgress,
  });
}

/// Builds the constrained option space and asks the AI to pick.
/// Falls back to [computeHeuristic] on any failure.
/// Returns [AiRecommendationResult] with metadata about whether AI was used.
///
/// [promptOverride] and [modelOverride] allow the test harness to pass
/// ad-hoc values without saving to preferences.
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
  String? promptOverride,
  String? modelOverride,
}) async {
  List<PlannedSetValues> fallback() => computeHeuristic(
      priorSets, weekGoal, movement, targetCount,
      autoProgress: autoProgress);

  // Quick guard: if AI is disabled or no API key, fall back immediately.
  // (Skip the guard when overrides are provided — test harness wants to run.)
  if (promptOverride == null && modelOverride == null) {
    try {
      if (!AppPreferences.getAiEnabled()) {
        return AiRecommendationResult(values: fallback(), usedAi: false);
      }
    } catch (_) {
      // Prefs not initialized (e.g. in tests) — fall back.
      return AiRecommendationResult(values: fallback(), usedAi: false);
    }
  }

  final heuristicValues = fallback();
  String? rawResponse;
  String? userMessage;
  String? effectivePrompt;
  String? effectiveModel;

  try {
    final options = _buildOptions(priorSets, weekGoal, movement, targetCount);
    final context = await AiContextBuilder.forRecommendation(
      mesocycleId: mesocycleId,
      weekNumber: weekNumber,
      weekGoal: weekGoal,
      workoutName: workoutName,
      workoutId: workoutId,
    );

    effectivePrompt = _withUserNotes(
        promptOverride ?? AppPreferences.getAiRecommendationPrompt());
    effectiveModel = modelOverride ?? AppPreferences.getAiModel();
    userMessage = _buildUserMessage(options, context);

    rawResponse = await AiService.chatCompletion(
      [
        {'role': 'system', 'content': effectivePrompt},
        {'role': 'user', 'content': userMessage},
      ],
      model: effectiveModel,
    );

    final pick = _parseResponse(rawResponse, options);
    final values = _pickToPlannedValues(pick, options, priorSets, movement);

    final successEntry = AiLogEntry(
      timestamp: DateTime.now(),
      movementName: movement.name,
      model: effectiveModel,
      systemPrompt: effectivePrompt,
      userMessage: userMessage,
      rawResponse: rawResponse,
      parseSuccess: true,
      aiResult: values,
      heuristicResult: heuristicValues,
    );
    AiResponseLog.instance.add(successEntry);
    // Fire-and-forget file export.
    AiLogWriter.writeEntry(successEntry);

    return AiRecommendationResult(values: values, usedAi: true);
  } catch (e) {
    final errorEntry = AiLogEntry(
      timestamp: DateTime.now(),
      movementName: movement.name,
      model: effectiveModel ?? 'unknown',
      systemPrompt: effectivePrompt ?? '',
      userMessage: userMessage ?? '',
      rawResponse: rawResponse,
      parseSuccess: false,
      parseError: rawResponse != null ? e.toString() : null,
      heuristicResult: heuristicValues,
      error: e.toString(),
    );
    AiResponseLog.instance.add(errorEntry);
    // Fire-and-forget file export.
    AiLogWriter.writeEntry(errorEntry);

    return AiRecommendationResult(
      values: heuristicValues,
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
  final setCount =
      priorSets.length > targetCount ? targetCount : priorSets.length;
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
  buf.writeln(
      '## Exercise to Plan: ${options.movementName} (${options.muscleGroup.name})');
  buf.writeln();

  // Show last week's numbers for reference.
  if (options.perSetOptions.isNotEmpty) {
    buf.writeln(
        'Last week they did ${options.perSetOptions.length} sets:');
    for (final s in options.perSetOptions) {
      final parts = <String>[];
      // The middle option is "same as last week".
      if (s.repsOptions.length >= 2) {
        parts.add('${s.repsOptions[s.repsOptions.length ~/ 2]} reps');
      }
      if (s.weightOptions.length >= 2) {
        parts.add('${s.weightOptions[s.weightOptions.length ~/ 2]}');
      }
      buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' x ')}');
    }
    buf.writeln();
  }

  buf.writeln('Available options (based on equipment increments):');
  buf.writeln('  Set count: ${options.setCountOptions.join(' or ')}');
  for (final s in options.perSetOptions) {
    final parts = <String>[];
    if (s.repsOptions.isNotEmpty) {
      parts.add('reps: ${s.repsOptions.join(", ")}');
    }
    if (s.weightOptions.isNotEmpty) {
      parts.add('weight: ${s.weightOptions.join(", ")}');
    }
    buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' | ')}');
  }
  buf.writeln();

  buf.writeln('Respond with this JSON (choose from the available options):');
  buf.writeln(
      '{"setCount": N, "sets": [{"setIndex": 0, "reps": N, "weight": N}, ...]}');
  buf.writeln('The "sets" array must have exactly "setCount" entries.');
  buf.writeln(
      'If you pick a setCount higher than the number of listed sets, repeat the last set\'s values for the extra sets.');

  return buf.toString();
}

// ── Response parsing ────────────────────────────────────────────────────────

ExercisePick _parseResponse(String response, ExerciseOptions options) {
  // Extract JSON from response (may be wrapped in markdown code blocks).
  var jsonStr = response.trim();
  final jsonMatch =
      RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
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

/// Runs a single AI call for every exercise in [exercises] and returns one
/// [AiRecommendationResult] per input (in the same order). Falls back to
/// [computeHeuristic] for any exercise the AI didn't provide a valid pick for.
Future<List<AiRecommendationResult>> computeBatchRecommendation({
  required List<BatchExerciseInput> exercises,
  required WeekGoal weekGoal,
  required int mesocycleId,
  required int weekNumber,
  required String workoutName,
  int? workoutId,
}) async {
  List<AiRecommendationResult> allFallback(String? error) => [
        for (final e in exercises)
          AiRecommendationResult(
            values: computeHeuristic(
                e.priorSets, weekGoal, e.movement, e.targetCount,
                autoProgress: true),
            usedAi: false,
            error: error,
          ),
      ];

  try {
    if (!AppPreferences.getAiEnabled()) return allFallback(null);
  } catch (_) {
    return allFallback(null);
  }

  final optionList = [
    for (final e in exercises)
      _buildOptions(e.priorSets, weekGoal, e.movement, e.targetCount),
  ];
  final heuristics = [
    for (final e in exercises)
      computeHeuristic(e.priorSets, weekGoal, e.movement, e.targetCount,
          autoProgress: true),
  ];

  String? rawResponse;
  String? userMessage;
  String effectivePrompt = '';
  String effectiveModel = '';

  try {
    final context = await AiContextBuilder.forRecommendation(
      mesocycleId: mesocycleId,
      weekNumber: weekNumber,
      weekGoal: weekGoal,
      workoutName: workoutName,
      workoutId: workoutId,
    );

    effectivePrompt = _withUserNotes(AppPreferences.getAiRecommendationPrompt());
    effectiveModel = AppPreferences.getAiModel();
    userMessage = _buildBatchUserMessage(optionList, context);

    rawResponse = await AiService.chatCompletion(
      [
        {'role': 'system', 'content': effectivePrompt},
        {'role': 'user', 'content': userMessage},
      ],
      model: effectiveModel,
    );

    final picks = _parseBatchResponse(rawResponse, optionList);

    final results = <AiRecommendationResult>[];
    for (var i = 0; i < exercises.length; i++) {
      final pick = picks[i];
      final AiRecommendationResult result;
      if (pick == null) {
        result = AiRecommendationResult(
          values: heuristics[i],
          usedAi: false,
          error: 'No valid AI pick for ${exercises[i].movement.name}',
        );
      } else {
        final values = _pickToPlannedValues(
            pick, optionList[i], exercises[i].priorSets, exercises[i].movement);
        result = AiRecommendationResult(values: values, usedAi: true);
      }
      results.add(result);

      final entry = AiLogEntry(
        timestamp: DateTime.now(),
        movementName: exercises[i].movement.name,
        model: effectiveModel,
        systemPrompt: effectivePrompt,
        userMessage: userMessage,
        rawResponse: rawResponse,
        parseSuccess: pick != null,
        aiResult: pick != null ? result.values : null,
        heuristicResult: heuristics[i],
        error: result.error,
      );
      AiResponseLog.instance.add(entry);
      AiLogWriter.writeEntry(entry);
    }
    return results;
  } catch (e) {
    for (var i = 0; i < exercises.length; i++) {
      final entry = AiLogEntry(
        timestamp: DateTime.now(),
        movementName: exercises[i].movement.name,
        model: effectiveModel.isEmpty ? 'unknown' : effectiveModel,
        systemPrompt: effectivePrompt,
        userMessage: userMessage ?? '',
        rawResponse: rawResponse,
        parseSuccess: false,
        parseError: rawResponse != null ? e.toString() : null,
        heuristicResult: heuristics[i],
        error: e.toString(),
      );
      AiResponseLog.instance.add(entry);
      AiLogWriter.writeEntry(entry);
    }
    return allFallback(e.toString());
  }
}

String _buildBatchUserMessage(
    List<ExerciseOptions> optionList, String historyContext) {
  final buf = StringBuffer();
  buf.writeln(historyContext);
  buf.writeln('## Workout Exercises to Plan');
  buf.writeln();

  for (var i = 0; i < optionList.length; i++) {
    final opts = optionList[i];
    buf.writeln(
        '### ${i + 1}. ${opts.movementName} (${opts.muscleGroup.name})');

    if (opts.perSetOptions.isNotEmpty) {
      buf.writeln('Last week:');
      for (final s in opts.perSetOptions) {
        final parts = <String>[];
        if (s.repsOptions.length >= 2) {
          parts.add('${s.repsOptions[s.repsOptions.length ~/ 2]} reps');
        }
        if (s.weightOptions.length >= 2) {
          parts.add('${s.weightOptions[s.weightOptions.length ~/ 2]}');
        }
        buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' x ')}');
      }
    }

    buf.writeln('Options:');
    buf.writeln('  Set count: ${opts.setCountOptions.join(' or ')}');
    for (final s in opts.perSetOptions) {
      final parts = <String>[];
      if (s.repsOptions.isNotEmpty) {
        parts.add('reps: ${s.repsOptions.join(", ")}');
      }
      if (s.weightOptions.isNotEmpty) {
        parts.add('weight: ${s.weightOptions.join(", ")}');
      }
      buf.writeln('  Set ${s.setIndex + 1}: ${parts.join(' | ')}');
    }
    buf.writeln();
  }

  buf.writeln(
      'Respond with this JSON (one entry per exercise in the same order — match by "movement" name):');
  buf.writeln('{"exercises": [');
  buf.writeln(
      '  {"movement": "name", "setCount": N, "sets": [{"setIndex": 0, "reps": N, "weight": N}, ...]}');
  buf.writeln(']}');
  buf.writeln('Each "sets" array must have exactly "setCount" entries.');
  buf.writeln(
      'If setCount is higher than the number of listed sets, repeat the last set\'s values for the extra sets.');

  return buf.toString();
}

List<ExercisePick?> _parseBatchResponse(
    String response, List<ExerciseOptions> optionList) {
  var jsonStr = response.trim();
  final jsonMatch =
      RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
  if (jsonMatch != null) jsonStr = jsonMatch.group(1)!.trim();

  final decoded = jsonDecode(jsonStr);
  List<dynamic> exArray;
  if (decoded is Map<String, dynamic> && decoded['exercises'] is List) {
    exArray = decoded['exercises'] as List<dynamic>;
  } else if (decoded is List) {
    exArray = decoded;
  } else {
    return List<ExercisePick?>.filled(optionList.length, null);
  }

  final byName = <String, Map<String, dynamic>>{};
  for (final e in exArray) {
    if (e is Map<String, dynamic>) {
      final name = e['movement'];
      if (name is String) byName[name.toLowerCase()] = e;
    }
  }

  final out = <ExercisePick?>[];
  for (var i = 0; i < optionList.length; i++) {
    final opts = optionList[i];
    Map<String, dynamic>? match = byName[opts.movementName.toLowerCase()];
    if (match == null && i < exArray.length && exArray[i] is Map<String, dynamic>) {
      match = exArray[i] as Map<String, dynamic>;
    }
    if (match == null) {
      out.add(null);
      continue;
    }
    try {
      final setCount = match['setCount'] as int;
      if (!opts.setCountOptions.contains(setCount)) {
        out.add(null);
        continue;
      }
      final setsJson = match['sets'] as List<dynamic>;
      final sets = <SetPick>[
        for (final s in setsJson)
          SetPick(
            reps: (s as Map<String, dynamic>)['reps'] as int?,
            weight: (s['weight'] as num?)?.toDouble(),
          ),
      ];
      out.add(ExercisePick(setCount: setCount, sets: sets));
    } catch (_) {
      out.add(null);
    }
  }
  return out;
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
