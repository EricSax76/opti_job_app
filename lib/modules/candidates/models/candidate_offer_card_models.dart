import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CandidateOfferMetricData {
  const CandidateOfferMetricData({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class CandidateOfferCardPalette {
  const CandidateOfferCardPalette({
    required this.ink,
    required this.muted,
    required this.borderColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.gradient,
    required this.tagBackgroundColor,
    required this.tagBorderColor,
    required this.tagTextColor,
  });

  final Color ink;
  final Color muted;
  final Color borderColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Gradient gradient;
  final Color tagBackgroundColor;
  final Color tagBorderColor;
  final Color tagTextColor;

  factory CandidateOfferCardPalette.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CandidateOfferCardPalette(
      ink: isDark ? uiDarkInk : uiInk,
      muted: isDark ? uiDarkMuted : uiMuted,
      borderColor: isDark ? uiDarkBorder : uiBorder,
      surfaceColor: isDark ? uiDarkSurfaceLight : uiBackground,
      backgroundColor: isDark ? uiDarkSurface : Colors.white,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [uiDarkCardGradientStart, uiDarkCardGradientEnd]
            : [Colors.white, const Color(0xFFF8F9FA)],
      ),
      tagBackgroundColor: uiAccent.withValues(alpha: isDark ? 0.2 : 0.1),
      tagBorderColor: uiAccent.withValues(alpha: isDark ? 0.35 : 0.2),
      tagTextColor: isDark ? uiAccent.withValues(alpha: 0.95) : uiAccent,
    );
  }
}

class CandidateOfferCardDecoration {
  const CandidateOfferCardDecoration({
    required this.borderColor,
    required this.borderWidth,
    required this.boxShadow,
  });

  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
}
