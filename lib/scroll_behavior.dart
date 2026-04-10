import 'dart:ui';

import 'package:flutter/material.dart';

/// Static flag checked by [GuardedScrollPhysics] to suppress scrolling
/// when the touch originated in the bottom 5% of the screen.
class ScrollGuard {
  ScrollGuard._();
  static bool blockScroll = false;
}

/// Wraps its [child] in a [Listener] that sets [ScrollGuard.blockScroll]
/// when a pointer goes down in the bottom 5% of the screen.
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
        if (event.position.dy > screenHeight * 0.95) {
          ScrollGuard.blockScroll = true;
        }
      },
      onPointerUp: (_) => ScrollGuard.blockScroll = false,
      onPointerCancel: (_) => ScrollGuard.blockScroll = false,
      child: child,
    );
  }
}

/// Scroll physics that suppresses all scroll movement and fling when
/// [ScrollGuard.blockScroll] is true.  Falls back to normal
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
    if (ScrollGuard.blockScroll) return 0.0;
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (ScrollGuard.blockScroll) return null;
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
