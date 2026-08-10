import 'package:flutter/services.dart';

import '../db/tables/enums.dart';

/// Delivers a timer cue through the Android foreground-service Flutter engine.
///
/// Unlike the UI cue service, this channel is owned by the foreground task and
/// does not depend on the app's UI isolate being scheduled while another app is
/// visible.
class WorkoutBackgroundCueDelivery {
  const WorkoutBackgroundCueDelivery({
    required this.delivered,
    required this.hapticDelivered,
  });

  final bool delivered;
  final bool hapticDelivered;
}

class WorkoutBackgroundCue {
  WorkoutBackgroundCue({
    MethodChannel channel = const MethodChannel(
      'com.clipclapclop.workoutofrecord/workout_cue',
    ),
  }) : _channel = channel;

  static final instance = WorkoutBackgroundCue();

  final MethodChannel _channel;

  /// Reports native acceptance and whether haptic feedback already occurred.
  Future<WorkoutBackgroundCueDelivery> fire({
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
      return WorkoutBackgroundCueDelivery(
        delivered: true,
        hapticDelivered: haptic,
      );
    } on MissingPluginException {
      return const WorkoutBackgroundCueDelivery(
        delivered: false,
        hapticDelivered: false,
      );
    } on PlatformException {
      // The native handler vibrates before attempting TTS. Avoid replaying the
      // haptic when speech falls back to the task isolate.
      return WorkoutBackgroundCueDelivery(
        delivered: false,
        hapticDelivered: haptic,
      );
    }
  }
}
