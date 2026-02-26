import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingCardPalette {
  const OnboardingCardPalette({
    required this.isDark,
    required this.gradientStart,
    required this.gradientEnd,
    required this.surfaceColor,
    required this.surfaceBorder,
    required this.topOrbColor,
    required this.sideOrbColor,
    required this.medallionRing,
    required this.medallionStart,
    required this.medallionEnd,
  });

  final bool isDark;
  final Color gradientStart;
  final Color gradientEnd;
  final Color surfaceColor;
  final Color surfaceBorder;
  final Color topOrbColor;
  final Color sideOrbColor;
  final Color medallionRing;
  final Color medallionStart;
  final Color medallionEnd;

  factory OnboardingCardPalette.fromTheme(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OnboardingCardPalette(
      isDark: isDark,
      gradientStart: isDark ? const Color(0xFF0B1423) : const Color(0xFFF7FAFF),
      gradientEnd: isDark ? const Color(0xFF111F35) : const Color(0xFFEEF3FB),
      surfaceColor: isDark
          ? const Color(0xFF142238).withValues(alpha: 0.93)
          : uiWhite.withValues(alpha: 0.96),
      surfaceBorder: isDark
          ? colorScheme.outline.withValues(alpha: 0.6)
          : const Color(0xFFD9E2EF),
      topOrbColor: isDark
          ? uiAccent.withValues(alpha: 0.14)
          : uiAccent.withValues(alpha: 0.09),
      sideOrbColor: isDark
          ? const Color(0xFF7C8AB0).withValues(alpha: 0.16)
          : const Color(0xFF97A6C7).withValues(alpha: 0.09),
      medallionRing: isDark
          ? colorScheme.primary.withValues(alpha: 0.4)
          : colorScheme.primary.withValues(alpha: 0.22),
      medallionStart: isDark ? const Color(0xFF182C47) : uiWhite,
      medallionEnd: isDark ? const Color(0xFF16253D) : const Color(0xFFF2F6FD),
    );
  }
}
