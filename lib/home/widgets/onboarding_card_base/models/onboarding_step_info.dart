import 'dart:math' as math;

class OnboardingStepInfo {
  const OnboardingStepInfo({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  static OnboardingStepInfo? resolve({int? stepIndex, int? totalSteps}) {
    if (stepIndex == null || totalSteps == null) return null;
    if (totalSteps < 2 || stepIndex < 1) return null;

    final boundedStep = math.min(stepIndex, totalSteps);
    return OnboardingStepInfo(currentStep: boundedStep, totalSteps: totalSteps);
  }
}
