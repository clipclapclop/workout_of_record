import 'package:flutter/services.dart';

import '../db/tables/enums.dart';

/// Delivers a timer cue through the Android foreground-service Flutter engine.
///
/// Unlike the UI cue service, this channel is owned by the foreground task and
/// does not depend on the app's UI isolate being scheduled while another app is
/// visible.
class WorkoutBackgroundCue {
  WorkoutBackgroundCue({
    MethodChannel channel = const MethodChannel(
      'com.clipclapclop.workoutofrecord/workout_cue',
    ),
  }) : _channel = channel;

  static final instance = WorkoutBackgroundCue();

  final MethodChannel _channel;

  /// Returns whether the native foreground-service channel accepted the cue.
  Future<bool> fire({
    required String? cueText,
    required TimerSound sound,
    required bool haptic,
  }) async {
    try {
      await _channel.invokeMethod<void>('fire', {
        'cueText': cueText,
        'sound': sound.name,
        'haptic': haptic,
      });
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
