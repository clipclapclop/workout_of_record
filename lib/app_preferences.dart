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

  static int? getAge() => _prefs.getInt(_kProfileAge);
  static Future<void> setAge(int? v) =>
      v == null ? _prefs.remove(_kProfileAge) : _prefs.setInt(_kProfileAge, v);

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

  // ── Settings ───────────────────────────────────────────────────────────────

  static bool getAiEnabled() => _prefs.getBool(_kSettingsAiEnabled) ?? true;
  static Future<void> setAiEnabled(bool v) => _prefs.setBool(_kSettingsAiEnabled, v);

  static Future<String?> getApiKey() => _secure.read(key: _kSettingsApiKey);
  static Future<void> setApiKey(String? v) => v == null
      ? _secure.delete(key: _kSettingsApiKey)
      : _secure.write(key: _kSettingsApiKey, value: v);

  // ── Keys ───────────────────────────────────────────────────────────────────

  static const _kCurrentMesocycleId = 'current_mesocycle_id';
  static const _kCurrentCompletedWorkoutId = 'current_completed_workout_id';
  static const _kHasSeenProfilePrompt = 'has_seen_profile_prompt';
  static const _kProfileAge = 'profile_age';
  static const _kProfileWeight = 'profile_weight_kg';
  static const _kProfileTrainingGoal = 'profile_training_goal';
  static const _kProfileCalorieState = 'profile_calorie_state';
  static const _kSettingsAiEnabled = 'settings_ai_enabled';
  static const _kSettingsApiKey = 'settings_api_key';
}
