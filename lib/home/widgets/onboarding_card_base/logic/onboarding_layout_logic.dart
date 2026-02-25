import 'dart:math' as math;

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingLayoutLogic {
  static double resolveTopGap({required double availableHeight}) {
    return _clamp(availableHeight * 0.14, 52, 132);
  }

  static double resolveMinContentHeight({
    required double availableHeight,
    required double mediaVerticalPadding,
  }) {
    return math.max(
      0,
      availableHeight - mediaVerticalPadding - (uiSpacing20 + uiSpacing24),
    );
  }

  static double _clamp(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }
}
