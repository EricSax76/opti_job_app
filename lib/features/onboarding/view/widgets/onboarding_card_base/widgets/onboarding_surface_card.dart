import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/onboarding/logic/onboarding_motion.dart';
import 'package:opti_job_app/features/onboarding/models/onboarding_card_palette.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_primary_button.dart';

class OnboardingSurfaceCard extends StatelessWidget {
  const OnboardingSurfaceCard({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryPressed,
    required this.body,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.secondaryIcon,
    required this.tertiaryLabel,
    required this.onTertiaryPressed,
    required this.primaryEnabled,
    required this.reduceMotion,
    required this.palette,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryPressed;
  final Widget? body;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData secondaryIcon;
  final String? tertiaryLabel;
  final VoidCallback? onTertiaryPressed;
  final bool primaryEnabled;
  final bool reduceMotion;
  final OnboardingCardPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget titleText = Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
        height: 1.1,
      ),
    );
    titleText = applyOnboardingEntranceMotion(
      child: titleText,
      enabled: !reduceMotion,
      delay: const Duration(milliseconds: 260),
      moveYBegin: 8,
    );

    Widget messageText = Text(
      message,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.45,
        letterSpacing: 0.1,
      ),
    );
    messageText = applyOnboardingEntranceMotion(
      child: messageText,
      enabled: !reduceMotion,
      delay: const Duration(milliseconds: 330),
      moveYBegin: 8,
    );

    Widget primaryButton = OnboardingPrimaryButton(
      label: primaryLabel,
      icon: primaryIcon,
      onPressed: onPrimaryPressed,
      reduceMotion: reduceMotion,
      enabled: primaryEnabled,
    );
    primaryButton = applyOnboardingEntranceMotion(
      child: primaryButton,
      enabled: !reduceMotion,
      delay: const Duration(milliseconds: 420),
      moveYBegin: 10,
      scaleBegin: 0.98,
    );

    Widget? customBody;
    if (body != null) {
      customBody = applyOnboardingEntranceMotion(
        child: body!,
        enabled: !reduceMotion,
        delay: const Duration(milliseconds: 400),
        moveYBegin: 10,
      );
    }

    Widget? secondaryButton;
    if (secondaryLabel != null && onSecondaryPressed != null) {
      secondaryButton = OutlinedButton.icon(
        onPressed: onSecondaryPressed,
        icon: Icon(secondaryIcon, size: 18),
        label: Text(secondaryLabel!),
      );
      secondaryButton = OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(168, 52),
            side: BorderSide(color: colorScheme.outlineVariant),
            foregroundColor: colorScheme.onSurface,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: secondaryButton,
      );
      secondaryButton = applyOnboardingEntranceMotion(
        child: secondaryButton,
        enabled: !reduceMotion,
        delay: const Duration(milliseconds: 460),
        moveYBegin: 10,
      );
    }

    Widget? tertiaryButton;
    if (tertiaryLabel != null && onTertiaryPressed != null) {
      tertiaryButton = TextButton(
        onPressed: onTertiaryPressed,
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(tertiaryLabel!),
      );
      tertiaryButton = applyOnboardingEntranceMotion(
        child: tertiaryButton,
        enabled: !reduceMotion,
        delay: const Duration(milliseconds: 500),
        moveYBegin: 6,
      );
    }

    final secondaryActions = secondaryButton == null
        ? null
        : <Widget>[secondaryButton];

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.surfaceBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.24 : 0.08),
            offset: const Offset(0, 18),
            blurRadius: 40,
            spreadRadius: -16,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.14 : 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(uiSpacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleText,
            const SizedBox(height: uiSpacing16),
            messageText,
            if (customBody != null) ...[
              const SizedBox(height: uiSpacing24),
              customBody,
            ],
            const SizedBox(height: uiSpacing24),
            Wrap(
              spacing: uiSpacing12,
              runSpacing: uiSpacing12,
              children: [primaryButton, ...?secondaryActions],
            ),
            if (tertiaryButton != null) ...[
              const SizedBox(height: uiSpacing8),
              Align(alignment: Alignment.centerLeft, child: tertiaryButton),
            ],
          ],
        ),
      ),
    );
  }
}
