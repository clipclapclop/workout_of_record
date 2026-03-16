import 'dart:async';

import 'package:flutter/material.dart';

import '../services/workout_cue_service.dart';
import 'rest_timer_controller.dart';

/// Displays a countdown rest timer with stop / reset / per-workout-toggle controls.
///
/// The widget polls [controller] at 200 ms intervals for smooth display and
/// fires [WorkoutCueService.fire] once when the countdown reaches zero.
///
/// [cueText] is what the cue service will speak in TTS mode (e.g. "10 reps").
/// Pass null when there is no meaningful planned value — the service falls back
/// to "ready" or a chime per its own settings.
///
/// [workoutTimerOn] / [onToggleWorkoutTimer] let the user kill the timer for
/// the rest of the workout session without touching global settings.
class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({
    super.key,
    required this.controller,
    required this.cueText,
  });

  final RestTimerController controller;
  final String? cueText;

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _ticker = Timer.periodic(const Duration(milliseconds: 200), _tick);
  }

  @override
  void didUpdateWidget(RestTimerWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _tick(Timer _) {
    if (!mounted) return;
    final ctrl = widget.controller;
    // Fire cue once when the running timer first hits zero.
    if (ctrl.isRunning && ctrl.remainingMs <= 0 && !ctrl.cued) {
      ctrl.markCued(); // stops ticking, sets cued=true, notifies
      WorkoutCueService.fire(widget.cueText);
    }
    if (mounted) setState(() {});
  }

  String _format(int ms) {
    final totalSeconds = (ms / 1000).ceil().clamp(0, 5999);
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final remaining = ctrl.remainingMs;
    final isRunning = ctrl.isRunning;
    final atZero = remaining <= 0 && !isRunning;

    final colorScheme = Theme.of(context).colorScheme;
    final Color displayColor = colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Countdown display
          SizedBox(
            width: 56,
            child: Text(
              _format(remaining),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: displayColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          const SizedBox(width: 4),
          // Stop / Play button
          IconButton(
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isRunning ? 'Stop' : (atZero ? 'Restart' : 'Resume'),
            onPressed: () {
              if (isRunning) {
                ctrl.stop();
              } else {
                ctrl.start();
              }
            },
          ),
          const SizedBox(width: 4),
          // Reset button
          IconButton(
            icon: const Icon(Icons.replay, size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Reset',
            onPressed: ctrl.reset,
          ),
        ],
      ),
    );
  }
}
