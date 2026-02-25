import 'package:flutter/material.dart';

class CandidateOnboardingStepViewModel {
  const CandidateOnboardingStepViewModel({
    required this.title,
    required this.message,
    required this.body,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryPressed,
    this.primaryEnabled = true,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.tertiaryLabel,
    this.onTertiaryPressed,
  });

  final String title;
  final String message;
  final Widget body;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryPressed;
  final bool primaryEnabled;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String? tertiaryLabel;
  final VoidCallback? onTertiaryPressed;
}
