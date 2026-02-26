import 'dart:math' as math;

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingStepInfo {
  const OnboardingStepInfo({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  static OnboardingStepInfo? resolve({int? stepIndex, int? totalSteps}) {
    if (stepIndex == null || totalSteps == null) return null;
    final minimumTrackableSteps = uiSpacing8 ~/ uiSpacing4;
    if (totalSteps < minimumTrackableSteps || stepIndex < 1) return null;

    final boundedStep = math.min(stepIndex, totalSteps);
    return OnboardingStepInfo(currentStep: boundedStep, totalSteps: totalSteps);
  }
}
