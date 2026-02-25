import 'package:flutter/material.dart';

import 'package:opti_job_app/home/widgets/onboarding_card_base/widgets/onboarding_card_base_layout.dart';

class OnboardingCardBase extends StatelessWidget {
  const OnboardingCardBase({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.primaryIcon = Icons.check_circle_outline_rounded,
    this.body,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.secondaryIcon = Icons.skip_next_rounded,
    this.tertiaryLabel,
    this.onTertiaryPressed,
    this.primaryEnabled = true,
    this.showHeaderMedallion = true,
    this.stepIndex,
    this.totalSteps,
    this.stepLabel,
    this.maxContentWidth = 520,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final IconData primaryIcon;
  final Widget? body;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData secondaryIcon;
  final String? tertiaryLabel;
  final VoidCallback? onTertiaryPressed;
  final bool primaryEnabled;
  final bool showHeaderMedallion;
  final int? stepIndex;
  final int? totalSteps;
  final String? stepLabel;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return OnboardingCardBaseLayout(
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimaryPressed: onPrimaryPressed,
      primaryIcon: primaryIcon,
      body: body,
      secondaryLabel: secondaryLabel,
      onSecondaryPressed: onSecondaryPressed,
      secondaryIcon: secondaryIcon,
      tertiaryLabel: tertiaryLabel,
      onTertiaryPressed: onTertiaryPressed,
      primaryEnabled: primaryEnabled,
      showHeaderMedallion: showHeaderMedallion,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      stepLabel: stepLabel,
      maxContentWidth: maxContentWidth,
    );
  }
}
