import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

Widget applyOnboardingEntranceMotion({
  required Widget child,
  required bool enabled,
  Duration delay = Duration.zero,
  double moveYBegin = 0,
  double scaleBegin = 1,
}) {
  if (!enabled) return child;
  final fadeDuration = Duration(
    milliseconds: uiDurationNormal.inMilliseconds - (uiSpacing20 * 2).toInt(),
  );
  final transformDuration = Duration(
    milliseconds: uiDurationSlow.inMilliseconds - (uiSpacing20 * 4).toInt(),
  );

  Animate animation = child
      .animate(delay: delay)
      .fadeIn(duration: fadeDuration, curve: Curves.easeOutCubic);

  if (moveYBegin != 0) {
    animation = animation.moveY(
      begin: moveYBegin,
      end: 0,
      duration: transformDuration,
      curve: Curves.easeOutCubic,
    );
  }

  if (scaleBegin != 1) {
    animation = animation.scale(
      begin: Offset(scaleBegin, scaleBegin),
      end: const Offset(1, 1),
      duration: transformDuration,
      curve: Curves.easeOutCubic,
    );
  }

  return animation;
}
