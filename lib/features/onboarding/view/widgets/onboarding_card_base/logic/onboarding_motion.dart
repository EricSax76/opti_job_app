import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

Widget applyOnboardingEntranceMotion({
  required Widget child,
  required bool enabled,
  Duration delay = Duration.zero,
  double moveYBegin = 0,
  double scaleBegin = 1,
}) {
  if (!enabled) return child;

  Animate animation = child
      .animate(delay: delay)
      .fadeIn(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );

  if (moveYBegin != 0) {
    animation = animation.moveY(
      begin: moveYBegin,
      end: 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  if (scaleBegin != 1) {
    animation = animation.scale(
      begin: Offset(scaleBegin, scaleBegin),
      end: const Offset(1, 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  return animation;
}
