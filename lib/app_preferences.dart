import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/tables/enums.dart';

/// Typed wrapper around SharedPreferences and FlutterSecureStorage.
///
/// Call [AppPreferences.init] once in main() before runApp.
/// All SharedPreferences getters are synchronous after init.
/// API key methods are async (flutter_secure_storage is always async).
class AppPreferences {
  AppPreferences._();

  static late SharedPreferences _prefs;
  static const _secure = FlutterSecureStorage();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey(_kProfileWeight)) {
      final legacyWeight = _prefs.getDouble(_kLegacyProfileWeightKg);
      if (legacyWeight != null) {
        // The retired unit toggle changed labels only; it never converted or
        // tagged stored values. This app has one existing owner-controlled data
        // set, confirmed as imperial. Copying exactly avoids corrupting it.
        await _prefs.setDouble(_kProfileWeight, legacyWeight);
      }
    }
    await _prefs.remove(_kLegacyProfileWeightKg);
    await _prefs.remove(_kLegacyUnitsMetric);
  }

  // ── Navigation state (acceleration pointers — ground truth is in the DB) ──

  static int? getCurrentMesocycleId() => _prefs.getInt(_kCurrentMesocycleId);
  static Future<void> setCurrentMesocycleId(int? id) =>
      id == null ? _prefs.remove(_kCurrentMesocycleId) : _prefs.setInt(_kCurrentMesocycleId, id);

  static int? getCurrentCompletedWorkoutId() => _prefs.getInt(_kCurrentCompletedWorkoutId);
  static Future<void> setCurrentCompletedWorkoutId(int? id) =>
      id == null ? _prefs.remove(_kCurrentCompletedWorkoutId) : _prefs.setInt(_kCurrentCompletedWorkoutId, id);

  // ── Onboarding ─────────────────────────────────────────────────────────────

  static bool hasSeenProfilePrompt() => _prefs.getBool(_kHasSeenProfilePrompt) ?? false;
  static Future<void> setHasSeenProfilePrompt(bool v) => _prefs.setBool(_kHasSeenProfilePrompt, v);

  // ── User profile ───────────────────────────────────────────────────────────

  static DateTime? getDateOfBirth() {
    final s = _prefs.getString(_kProfileDateOfBirth);
    return s == null ? null : DateTime.parse(s);
  }
  static Future<void> setDateOfBirth(DateTime? v) => v == null
      ? _prefs.remove(_kProfileDateOfBirth)
      : _prefs.setString(_kProfileDateOfBirth, v.toIso8601String());

  static double? getWeight() => _prefs.getDouble(_kProfileWeight);
  static Future<void> setWeight(double? v) =>
      v == null ? _prefs.remove(_kProfileWeight) : _prefs.setDouble(_kProfileWeight, v);

  static TrainingGoal? getTrainingGoal() {
    final s = _prefs.getString(_kProfileTrainingGoal);
    return s == null ? null : TrainingGoal.values.byName(s);
  }
  static Future<void> setTrainingGoal(TrainingGoal? v) =>
      v == null ? _prefs.remove(_kProfileTrainingGoal) : _prefs.setString(_kProfileTrainingGoal, v.name);

  static CalorieState? getCalorieState() {
    final s = _prefs.getString(_kProfileCalorieState);
    return s == null ? null : CalorieState.values.byName(s);
  }
  static Future<void> setCalorieState(CalorieState? v) =>
      v == null ? _prefs.remove(_kProfileCalorieState) : _prefs.setString(_kProfileCalorieState, v.name);

  static DateTime? getTrainingStartDate() {
    final s = _prefs.getString(_kProfileTrainingStartDate);
    return s == null ? null : DateTime.parse(s);
  }
  static Future<void> setTrainingStartDate(DateTime? v) => v == null
      ? _prefs.remove(_kProfileTrainingStartDate)
      : _prefs.setString(_kProfileTrainingStartDate, v.toIso8601String());

  // ── Settings ───────────────────────────────────────────────────────────────

  static bool getAiEnabled() => _prefs.getBool(_kSettingsAiEnabled) ?? true;
  static Future<void> setAiEnabled(bool v) => _prefs.setBool(_kSettingsAiEnabled, v);

  static Future<String?> getApiKey() =>
      _secure.read(key: _kSettingsCredential);
  static Future<void> setApiKey(String? v) => v == null
      ? _secure.delete(key: _kSettingsCredential)
      : _secure.write(key: _kSettingsCredential, value: v);

  // ── AI ─────────────────────────────────────────────────────────────────────

  static String getAiModel() => _prefs.getString(_kAiModel) ?? defaultAiModel;
  static Future<void> setAiModel(String v) => _prefs.setString(_kAiModel, v);

  static String? getAiCreditId() => _prefs.getString(_kAiCreditId);
  static Future<void> setAiCreditId(String? v) =>
      v == null ? _prefs.remove(_kAiCreditId) : _prefs.setString(_kAiCreditId, v);

  static String getAiRecommendationPrompt() =>
      _prefs.getString(_kAiRecommendationPrompt) ?? defaultRecommendationPrompt;
  static Future<void> setAiRecommendationPrompt(String v) =>
      _prefs.setString(_kAiRecommendationPrompt, v);

  static String getAiChatPrompt() =>
      _prefs.getString(_kAiChatPrompt) ?? defaultChatPrompt;
  static Future<void> setAiChatPrompt(String v) =>
      _prefs.setString(_kAiChatPrompt, v);

  static int getAiHistoryWeeks() => _prefs.getInt(_kAiHistoryWeeks) ?? 4;
  static Future<void> setAiHistoryWeeks(int v) =>
      _prefs.setInt(_kAiHistoryWeeks, v);

  /// Free-form user notes appended to the recommendation system prompt.
  /// Meant for temporary context (injuries, travel, etc.) that shouldn't
  /// dirty up the main prompt.
  static String getAiUserNotes() => _prefs.getString(_kAiUserNotes) ?? '';
  static Future<void> setAiUserNotes(String v) =>
      v.isEmpty ? _prefs.remove(_kAiUserNotes) : _prefs.setString(_kAiUserNotes, v);

  static bool getAiLoggingEnabled() => _prefs.getBool(_kAiLoggingEnabled) ?? false;
  static Future<void> setAiLoggingEnabled(bool v) => _prefs.setBool(_kAiLoggingEnabled, v);

  static String? getAiLogDirectoryPath() => _prefs.getString(_kAiLogDirectoryPath);
  static Future<void> setAiLogDirectoryPath(String? v) => v == null
      ? _prefs.remove(_kAiLogDirectoryPath)
      : _prefs.setString(_kAiLogDirectoryPath, v);

  static const defaultAiModel = 'gpt-5.4-mini';

  static const defaultRecommendationPrompt = '''
Assume you are a personal trainer who is up on the latest training literature, and who isn't concerned with following the latest fad but does want to give good, modern guidance.

Your goal is to give a person exact goal values and targets for a pre-prescribed group of exercises based on their particular past workout results, feedback, and other such info.

Regarding Effort, Volume, Pump, Joint Pain, and Soreness feedback, interpret it as you would if you asked "How was your..." and they responded with the associated value.

Similarly, account for their training goal when setting the workout.

Regarding hard vs deload weeks: each mesocycle is N hard weeks followed by one easy (deload) week, and so each week should be planned appropriately based on whether it is a hard or deload week so that they will maximize their results over the long term.

You must choose from the available options provided for set count, reps, and weight. These represent what is physically loadable on the equipment. Return ONLY the JSON response, no explanation.''';

  static const defaultChatPrompt = '''
Assume you are a personal trainer who is up on the latest training literature, and who isn't concerned with following the latest fad but does want to give good, modern guidance.

You have access to this person's recent workout history and profile (provided below). Answer their questions based on their actual data — reference specific numbers, exercises, and trends when relevant.

Regarding Effort, Volume, Pump, Joint Pain, and Soreness feedback, interpret it as you would if you asked "How was your..." and they responded with the associated value.

Keep answers focused and practical. When suggesting changes, be specific about exercises, sets, reps, and weights.''';

  // ── Notes ──────────────────────────────────────────────────────────────────

  static String getNotes() => _prefs.getString(_kNotes) ?? '';
  static Future<void> setNotes(String v) =>
      v.isEmpty ? _prefs.remove(_kNotes) : _prefs.setString(_kNotes, v);

  // ── Timer ──────────────────────────────────────────────────────────────────

  static bool getTimerEnabled() => _prefs.getBool(_kTimerEnabled) ?? true;
  static Future<void> setTimerEnabled(bool v) => _prefs.setBool(_kTimerEnabled, v);

  /// Default rest duration in seconds when a movement has no override. Default 60.
  static int getTimerDefaultSeconds() => _prefs.getInt(_kTimerDefaultSeconds) ?? 60;
  static Future<void> setTimerDefaultSeconds(int v) => _prefs.setInt(_kTimerDefaultSeconds, v);

  static TimerSound getTimerSound() {
    final s = _prefs.getString(_kTimerSound);
    return s == null ? TimerSound.tts : TimerSound.values.byName(s);
  }
  static Future<void> setTimerSound(TimerSound v) => _prefs.setString(_kTimerSound, v.name);

  static bool getTimerHaptic() => _prefs.getBool(_kTimerHaptic) ?? true;
  static Future<void> setTimerHaptic(bool v) => _prefs.setBool(_kTimerHaptic, v);

  static bool getTimerKeepAwake() => _prefs.getBool(_kTimerKeepAwake) ?? false;
  static Future<void> setTimerKeepAwake(bool v) => _prefs.setBool(_kTimerKeepAwake, v);

  static bool getTimerGetReadyChimes() =>
      _prefs.getBool(_timerGetReadyChimesPreference) ?? false;
  static Future<void> setTimerGetReadyChimes(bool v) =>
      _prefs.setBool(_timerGetReadyChimesPreference, v);

  // ── Backup ─────────────────────────────────────────────────────────────────

  static bool getBackupEnabled() => _prefs.getBool(_kBackupEnabled) ?? false;
  static Future<void> setBackupEnabled(bool v) => _prefs.setBool(_kBackupEnabled, v);

  static bool getAutoBackupEnabled() => _prefs.getBool(_kAutoBackupEnabled) ?? false;
  static Future<void> setAutoBackupEnabled(bool v) => _prefs.setBool(_kAutoBackupEnabled, v);

  static String? getBackupDirectoryPath() => _prefs.getString(_kBackupDirectoryPath);
  static Future<void> setBackupDirectoryPath(String? v) => v == null
      ? _prefs.remove(_kBackupDirectoryPath)
      : _prefs.setString(_kBackupDirectoryPath, v);

  static DateTime? getLastBackupTimestamp() {
    final s = _prefs.getString(_kLastBackupTimestamp);
    return s == null ? null : DateTime.parse(s);
  }
  static Future<void> setLastBackupTimestamp(DateTime? v) => v == null
      ? _prefs.remove(_kLastBackupTimestamp)
      : _prefs.setString(_kLastBackupTimestamp, v.toIso8601String());

  static String? getLastBackupError() => _prefs.getString(_kLastBackupError);
  static Future<void> setLastBackupError(String? v) => v == null
      ? _prefs.remove(_kLastBackupError)
      : _prefs.setString(_kLastBackupError, v);

  // ── Keys ───────────────────────────────────────────────────────────────────

  static const _kCurrentMesocycleId = 'current_mesocycle_id';
  static const _kCurrentCompletedWorkoutId = 'current_completed_workout_id';
  static const _kHasSeenProfilePrompt = 'has_seen_profile_prompt';
  static const _kProfileDateOfBirth = 'profile_date_of_birth';
  static const _kProfileWeight = 'profile_weight_lbs';
  static const _kLegacyProfileWeightKg = 'profile_weight_kg';
  static const _kProfileTrainingGoal = 'profile_training_goal';
  static const _kProfileCalorieState = 'profile_calorie_state';
  static const _kProfileTrainingStartDate = 'profile_training_start_date';
  static const _kSettingsAiEnabled = 'settings_ai_enabled';
  static const _kLegacyUnitsMetric = 'settings_units_metric';
  static const _kSettingsCredential = 'settings_api_key';
  static const _kAiModel = 'ai_model';
  static const _kAiCreditId = 'ai_credit_id';
  static const _kAiRecommendationPrompt = 'ai_recommendation_prompt';
  static const _kAiChatPrompt = 'ai_chat_prompt';
  static const _kAiHistoryWeeks = 'ai_history_weeks';
  static const _kAiUserNotes = 'ai_user_notes';
  static const _kAiLoggingEnabled = 'ai_logging_enabled';
  static const _kAiLogDirectoryPath = 'ai_log_directory_path';
  static const _kTimerEnabled = 'timer_enabled';
  static const _kTimerDefaultSeconds = 'timer_default_seconds';
  static const _kTimerSound = 'timer_sound';
  static const _kTimerHaptic = 'timer_haptic';
  static const _kTimerKeepAwake = 'timer_keep_awake';
  static const _timerGetReadyChimesPreference = 'timer_get_ready_chimes';
  static const _kBackupEnabled = 'backup_enabled';
  static const _kAutoBackupEnabled = 'auto_backup_enabled';
  static const _kBackupDirectoryPath = 'backup_directory_path';
  static const _kLastBackupTimestamp = 'backup_last_timestamp';
  static const _kLastBackupError = 'backup_last_error';
  static const _kNotes = 'notes';
}
