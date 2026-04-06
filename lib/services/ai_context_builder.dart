import '../app_preferences.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../db/workout_data.dart';

/// Builds structured text context from workout history for AI prompts.
class AiContextBuilder {
  AiContextBuilder._();

  /// Builds context for the recommendation system.
  /// Includes user profile, current meso structure, and recent history.
  static Future<String> forRecommendation({
    required int mesocycleId,
    required int weekNumber,
    required WeekGoal weekGoal,
    required String workoutName,
    int? workoutId,
    int? historyWeeks,
  }) async {
    final weeks = historyWeeks ?? AppPreferences.getAiHistoryWeeks();
    final buf = StringBuffer();

    _appendProfile(buf);
    buf.writeln('## Current Context');
    buf.writeln('Week $weekNumber of mesocycle, goal: ${weekGoal.name}');
    buf.writeln('Workout: $workoutName');
    buf.writeln();

    // Include today's pre-workout check-in if available.
    if (workoutId != null) {
      await _appendPreWorkoutCheckin(buf, workoutId);
    }

    await _appendRecentHistory(buf, weeks);

    return buf.toString();
  }

  /// Builds context for the chat system.
  /// Includes user profile and recent training history.
  static Future<String> forChat({int? historyWeeks}) async {
    final weeks = historyWeeks ?? AppPreferences.getAiHistoryWeeks();
    final buf = StringBuffer();

    _appendProfile(buf);

    final mesoId = AppPreferences.getCurrentMesocycleId();
    if (mesoId != null) {
      await _appendCurrentMesoInfo(buf, mesoId);
    }

    await _appendRecentHistory(buf, weeks);

    return buf.toString();
  }

  /// Builds context for chat when opened from the workout screen.
  /// Includes the current in-progress workout data.
  static Future<String> forWorkoutChat({
    required int completedWorkoutId,
    int? historyWeeks,
  }) async {
    final weeks = historyWeeks ?? AppPreferences.getAiHistoryWeeks();
    final buf = StringBuffer();

    _appendProfile(buf);

    try {
      final workoutData = await db.getWorkoutData(completedWorkoutId);
      buf.writeln('## Current Workout In Progress');
      _appendWorkoutDetail(buf, workoutData);
      buf.writeln();
    } catch (_) {
      // Workout may not be available; continue without it.
    }

    await _appendRecentHistory(buf, weeks);

    return buf.toString();
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  static void _appendProfile(StringBuffer buf) {
    buf.writeln('## Lifter Profile');

    final dob = AppPreferences.getDateOfBirth();
    if (dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      buf.writeln('Age: $age');
    }

    final weight = AppPreferences.getWeight();
    final metric = AppPreferences.getUnitsMetric();
    if (weight != null) {
      buf.writeln('Body weight: ${weight.toStringAsFixed(1)} ${metric ? 'kg' : 'lbs'}');
    }

    final goal = AppPreferences.getTrainingGoal();
    if (goal != null) buf.writeln('Training goal: ${goal.name}');

    final cals = AppPreferences.getCalorieState();
    if (cals != null) buf.writeln('Calorie state: ${cals.name}');

    final startDate = AppPreferences.getTrainingStartDate();
    if (startDate != null) {
      final months = DateTime.now().difference(startDate).inDays ~/ 30;
      buf.writeln('Training experience: ~$months months');
    }

    buf.writeln('Units: ${metric ? 'metric (kg)' : 'imperial (lbs)'}');
    buf.writeln();
  }

  // ── Pre-workout check-in ─────────────────────────────────────────────────────

  static Future<void> _appendPreWorkoutCheckin(StringBuffer buf, int workoutId) async {
    try {
      final checkin = await db.getPreWorkoutCheckin(workoutId);
      if (checkin == null) return;

      buf.writeln('## Today\'s Pre-Workout Check-in');

      // Readiness
      if (checkin.sleepQuality != null) buf.writeln('Sleep quality: ${checkin.sleepQuality!.name}');
      if (checkin.vimVigor != null) buf.writeln('Energy/vigor: ${checkin.vimVigor!.name}');
      if (checkin.mentalState != null) buf.writeln('Mental state: ${checkin.mentalState!.name}');

      // Soreness — only mention non-none values to keep it concise.
      final sorenessMap = <String, Soreness?>{
        'quads': checkin.quads,
        'hamstrings': checkin.hamstrings,
        'abs': checkin.abs,
        'chest': checkin.chest,
        'back': checkin.back,
        'biceps': checkin.biceps,
        'triceps': checkin.triceps,
        'traps': checkin.traps,
        'forearms': checkin.forearms,
        'glutes': checkin.glutes,
        'calves': checkin.calves,
        'shoulders': checkin.shoulders,
        'tibialis': checkin.tibialis,
      }.entries.where((e) => e.value != null && e.value != Soreness.none);

      if (sorenessMap.isNotEmpty) {
        buf.writeln('Muscle soreness:');
        for (final e in sorenessMap) {
          buf.writeln('  ${e.key}: ${e.value!.name}');
        }
      }
      buf.writeln();
    } catch (_) {
      // Check-in may not exist yet; skip.
    }
  }

  // ── Current meso info ───────────────────────────────────────────────────────

  static Future<void> _appendCurrentMesoInfo(StringBuffer buf, int mesoId) async {
    try {
      final calendar = await db.getMesocycleCalendar(mesoId);
      buf.writeln('## Current Mesocycle');
      buf.writeln('Name: ${calendar.mesoName}');
      buf.writeln('Total weeks: ${calendar.totalWeekCount}');
      buf.writeln();
    } catch (_) {
      // Calendar may not load; skip.
    }
  }

  // ── Recent history ──────────────────────────────────────────────────────────

  static Future<void> _appendRecentHistory(StringBuffer buf, int maxWeeks) async {
    final summaries = await db.getCompletedWorkoutSummaries();

    if (summaries.isEmpty) {
      buf.writeln('## Training History');
      buf.writeln('No completed workouts yet.');
      buf.writeln();
      return;
    }

    // Filter to most recent N weeks worth of workouts.
    // Use date-based filtering: workouts within the last (maxWeeks * 7) days.
    final cutoff = DateTime.now().subtract(Duration(days: maxWeeks * 7));
    final recent = summaries
        .where((s) => s.completedWorkout.startedAt.isAfter(cutoff))
        .toList();

    if (recent.isEmpty) {
      buf.writeln('## Training History');
      buf.writeln('No workouts in the last $maxWeeks weeks.');
      buf.writeln();
      return;
    }

    buf.writeln('## Training History (last $maxWeeks weeks, ${recent.length} workouts)');
    buf.writeln();

    // Load full details for each recent workout (limit to keep token count sane)
    final toDetail = recent.take(20).toList();
    for (final summary in toDetail) {
      try {
        final data = await db.getWorkoutData(summary.completedWorkout.id);
        buf.writeln('### ${summary.mesoName} — Week ${summary.weekNumber} — ${summary.workoutName}');
        buf.writeln('Date: ${_formatDate(summary.completedWorkout.startedAt)}');
        _appendWorkoutDetail(buf, data);
        buf.writeln();
      } catch (_) {
        // Skip workouts that fail to load.
      }
    }
  }

  static void _appendWorkoutDetail(StringBuffer buf, WorkoutData data) {
    for (final ex in data.exercises) {
      final skip = ex.completed.skipReason;
      if (skip != null) {
        buf.writeln('- ${ex.movement.name} [${ex.movement.muscleGroup.name}]: SKIPPED (${skip.name})');
        continue;
      }

      buf.write('- ${ex.movement.name} [${ex.movement.muscleGroup.name}]:');
      final setStrs = <String>[];
      for (final s in ex.sets) {
        if (s.completed.skipReason != null) {
          setStrs.add('skipped');
          continue;
        }
        final parts = <String>[];
        if (s.completed.reps != null) parts.add('${s.completed.reps} reps');
        if (s.completed.weight != null) parts.add('${s.completed.weight} ${AppPreferences.getUnitsMetric() ? 'kg' : 'lbs'}');
        if (s.completed.time != null) parts.add('${s.completed.time}s');
        if (s.completed.distance != null) parts.add('${s.completed.distance}m');
        setStrs.add(parts.isEmpty ? 'empty' : parts.join(' x '));
      }
      buf.writeln(' ${setStrs.join(' | ')}');

      if (ex.postExerciseCheckin != null) {
        buf.writeln('  Joint pain: ${ex.postExerciseCheckin!.jointPain.name}');
      }
    }

    // Muscle group check-ins
    if (data.postMuscleGroupCheckins.isNotEmpty) {
      buf.writeln('Muscle group feedback:');
      for (final mg in data.postMuscleGroupCheckins) {
        buf.writeln('  ${mg.muscleGroup.name}: effort=${mg.effortLevel.name}, volume=${mg.volumeLevel.name}, pump=${mg.pumpLevel.name}');
      }
    }
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
