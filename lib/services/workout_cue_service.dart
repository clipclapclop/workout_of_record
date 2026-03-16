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

  static Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  /// Call when the timer reaches zero.
  ///
  /// [cueText] is the value to speak in TTS mode (e.g. "10 reps",
  /// "45 seconds", "80 kg").  Pass null when there is no meaningful value —
  /// the service will fall back to saying "ready" or doing nothing.
  static Future<void> fire(String? cueText) async {
    final haptic = AppPreferences.getTimerHaptic();
    final sound = AppPreferences.getTimerSound();

    if (haptic) {
      await HapticFeedback.heavyImpact();
    }

    if (sound == TimerSound.silent) return;

    await _init();

    if (sound == TimerSound.tts && cueText != null) {
      await _tts.speak(cueText);
    } else {
      // Chime mode, or TTS mode with no cue text: say "ready".
      await _tts.speak('ready');
    }
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}
