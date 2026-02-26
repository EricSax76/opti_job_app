import 'package:flutter/material.dart';

import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.greeting,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.stepIndex,
    this.totalSteps,
    this.stepLabel,
  });

  final String greeting;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final int? stepIndex;
  final int? totalSteps;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return OnboardingCardBase(
      title: greeting,
      message: message,
      primaryLabel: confirmLabel,
      onPrimaryPressed: onConfirm,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      stepLabel: stepLabel,
    );
  }
}
