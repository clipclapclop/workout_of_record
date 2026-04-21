import 'dart:ui';

import 'package:flutter/material.dart';

/// Tracks whether a recent touch originated in the bottom gesture zone.
/// Uses a timestamp instead of a simple bool so the block survives the
/// pointer-cancel → fling-creation timing gap.
class ScrollGuard {
  ScrollGuard._();

  /// When the last bottom-zone pointer went down.  Null = no active block.
  static DateTime? _blockedAt;

  /// How long to keep the block after the pointer ends.  Covers the gap
  /// between onPointerCancel (system steals gesture) and
  /// createBallisticSimulation (Flutter tries to fling).
  static const _blockDuration = Duration(milliseconds: 400);

  static void block() => _blockedAt = DateTime.now();

  static void unblock() => _blockedAt = null;

  static bool get isBlocked {
    if (_blockedAt == null) return false;
    if (DateTime.now().difference(_blockedAt!) < _blockDuration) return true;
    // Expired — clean up.
    _blockedAt = null;
    return false;
  }
}

/// Wraps its [child] in a [Listener] that activates [ScrollGuard]
/// when a pointer goes down in the bottom 10% of the screen.
///
/// Must be placed above the [Navigator] (e.g. via [MaterialApp.builder])
/// so it covers ALL routes, not just the initial one.
///
/// [Listener] is passive — it does not participate in the gesture arena,
/// so taps on buttons in the bottom zone still work normally.
class ScrollGuardListener extends StatelessWidget {
  const ScrollGuardListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final screenHeight =
            PlatformDispatcher.instance.views.first.physicalSize.height /
                PlatformDispatcher.instance.views.first.devicePixelRatio;
        if (event.position.dy > screenHeight * 0.90) {
          ScrollGuard.block();
        }
      },
      // Only clear on a natural lift — NOT on cancel (system stealing the
      // gesture).  The timestamp expiry handles cleanup for cancelled pointers.
      onPointerUp: (_) => ScrollGuard.unblock(),
      child: child,
    );
  }
}

/// Scroll physics that suppresses all scroll movement and fling when
/// [ScrollGuard.isBlocked] is true.  Falls back to normal
/// [ClampingScrollPhysics] otherwise, with a secondary drag-start
/// threshold as an extra buffer.
class GuardedScrollPhysics extends ClampingScrollPhysics {
  const GuardedScrollPhysics({super.parent});

  @override
  GuardedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return GuardedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double? get dragStartDistanceMotionThreshold => 24.0;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (ScrollGuard.isBlocked) return 0.0;
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (ScrollGuard.isBlocked) return null;
    return super.createBallisticSimulation(position, velocity);
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const GuardedScrollPhysics();
  }
}
