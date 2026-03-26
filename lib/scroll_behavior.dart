import 'package:flutter/material.dart';

/// Custom scroll physics that requires intentional drag distance before
/// scrolling engages. Prevents Android gesture-nav swipe-up from triggering
/// unwanted scroll/fling in the app.
class ResistantScrollPhysics extends ClampingScrollPhysics {
  const ResistantScrollPhysics({super.parent});

  @override
  ResistantScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ResistantScrollPhysics(parent: buildParent(ancestor));
  }

  /// Logical pixels the pointer must move before the drag is accepted.
  /// Default ClampingScrollPhysics has NO threshold (null → instant scroll).
  /// 24 lp ≈ 4-5 mm on a typical phone — enough to ignore a quick system
  /// gesture swipe while still feeling responsive for intentional scrolls.
  @override
  double? get dragStartDistanceMotionThreshold => 24.0;
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ResistantScrollPhysics();
  }
}
