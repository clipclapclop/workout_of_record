import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';

/// Fires the rest-timer cue (TTS, chime, haptic) when the countdown hits zero.
///
/// Intentionally decoupled from the timer widget — the timer just calls
/// [WorkoutCueService.fire] with an optional string and this class decides
/// how to deliver it based on global settings.  This makes it straightforward
/// to extend (e.g. yoga pose narration) without touching timer logic.
class WorkoutCueService {
  WorkoutCueService._();

  static final _tts = FlutterTts();
  static bool _initialized = false;

  /// Best-effort init. Returns true if TTS is usable, false if no engine is
  /// available (common on GrapheneOS / de-Googled devices) or any other error.
  ///
  /// Re-applies language/rate/volume every time to guard against the engine
  /// becoming unavailable between calls (system reclaiming resources, engine
  /// crash, etc.).  One-time config (audio attributes, await mode) is only
  /// set on first successful init.
  static Future<bool> _init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
      await _tts.setVolume(1.0);
      if (!_initialized) {
        // Route TTS through navigation-guidance audio attributes — Android
        // treats this as high-priority speech that plays over other audio and
        // isn't silenced by low media/ring volume.
        await _tts.setAudioAttributesForNavigation();
        await _tts.awaitSpeakCompletion(false);
      }
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// Returns true if a TTS engine is installed and usable on this device.
  /// Used by Settings to warn the user when no engine is present.
  static Future<bool> isAvailable() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is! List || engines.isEmpty) return false;
      // Some devices report an engine list but no working default.
      final def = await _tts.getDefaultEngine;
      return def != null && def.toString().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Call when the timer reaches zero.
  ///
  /// [cueText] is the value to speak in TTS mode (e.g. "10 reps",
  /// "45 seconds", "80 kg").  Pass null when there is no meaningful value —
  /// the service will fall back to saying "ready" or doing nothing.
  ///
  /// All TTS calls are wrapped in try/catch so a missing engine (e.g. on
  /// GrapheneOS without Google TTS) degrades to haptic-only instead of
  /// crashing the workout.
  static Future<bool> fire(
    String? cueText, {
    TimerSound? soundOverride,
    bool? hapticOverride,
  }) async {
    final haptic = hapticOverride ?? AppPreferences.getTimerHaptic();
    final sound = soundOverride ?? AppPreferences.getTimerSound();

    if (haptic) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (sound == TimerSound.silent) return true;

    final ok = await _init();
    if (!ok) return false;

    try {
      final text = (sound == TimerSound.tts && cueText != null)
          ? cueText
          : 'ready';
      // focus: true requests audio focus before speaking, ensuring TTS is
      // audible even when another app holds focus or the device is idle.
      final result = await _tts.speak(text, focus: true);
      return result == 1;
    } catch (_) {
      // No engine, language unsupported, or platform error — silently degrade.
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
