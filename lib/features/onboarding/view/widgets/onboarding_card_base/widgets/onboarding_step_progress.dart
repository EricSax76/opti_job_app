import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingStepProgress extends StatelessWidget {
  const OnboardingStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.label,
  });

  final int currentStep;
  final int totalSteps;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = colorScheme.primary;
    final inactiveColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.65)
        : colorScheme.outline.withValues(alpha: 0.75);
    final stepLabel =
        label ??
        '${currentStep.toString().padLeft(2, '0')} / ${totalSteps.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: uiSpacing12),
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber <= currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : uiSpacing8,
                ),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(uiPillRadius),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
