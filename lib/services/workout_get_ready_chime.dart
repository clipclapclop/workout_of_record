import 'package:flutter/services.dart';

enum GetReadyChime { tenSeconds, fiveSeconds }

/// Returns the most urgent threshold crossed by a descending countdown.
/// Starting at or below a threshold does not produce an immediate chime.
GetReadyChime? getReadyChimeCrossed(int previousMs, int currentMs) {
  if (previousMs > 5000 && currentMs <= 5000) {
    return GetReadyChime.fiveSeconds;
  }
  if (previousMs > 10000 && currentMs <= 10000) {
    return GetReadyChime.tenSeconds;
  }
  return null;
}

/// Plays the built-in get-ready tones through the Android engine that owns the
/// active timer. The same channel is also registered on the UI engine so a
/// visible workout can still chime when its foreground service is unavailable.
class WorkoutGetReadyChimeService {
  WorkoutGetReadyChimeService._();

  static const _channel = MethodChannel(
    'com.clipclapclop.workoutofrecord/get_ready_chime',
  );

  static Future<bool> play(GetReadyChime chime) async {
    try {
      await _channel.invokeMethod<void>('play', {'chime': chime.name});
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
