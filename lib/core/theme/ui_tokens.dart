import 'package:flutter/material.dart';

// Light Theme Colors
const uiInk = Color(0xFF0F172A);
const uiMuted = Color(0xFF475569);
const uiBorder = Color(0xFFE2E8F0);
const uiBackground = Color(0xFFF8FAFC);
const uiAccent = Color(0xFF3FA7A0);
const uiAccentSoft = Color(0xFFF1F7F6);
const uiLightPrimary = Color(0xFF4A66D8);
const uiLightPrimaryContainer = Color(0xFFEAF0FF);
const uiLightOnPrimaryContainer = Color(0xFF1F2E52);
const uiLightSecondaryContainer = Color(0xFFE9EEF8);
const uiLightOnSecondaryContainer = Color(0xFF2A3652);
const uiLightHeaderGradientStart = Color(0xFFEAF0FF);
const uiLightHeaderGradientEnd = Color(0xFFDEE7FF);
const uiLightMetricSalary = Color(0xFF4F7D66);
const uiLightMetricLocation = Color(0xFF5F6F8D);
const uiLightMetricModality = Color(0xFF5A6EA3);
const uiLightTagText = Color(0xFF425A8B);
const uiError = Color(0xFFEF4444);
const uiSuccess = Color(0xFF10B981);
const uiWhite = Colors.white;

// Dark Theme Colors
const uiDarkInk = Color(0xFFF1F5F9);
const uiDarkMuted = Color(0xFF94A3B8);
const uiDarkBorder = Color(0xFF1E293B);
const uiDarkBackground = Color(0xFF0F172A);
const uiDarkSurface = Color(0xFF1E293B);
const uiDarkSurfaceLight = Color(0xFF334155);
const uiDarkAccentSoft = Color(0xFF132F2E);
const uiDarkPrimary = Color(0xFF6F8CFF);
const uiDarkPrimaryContainer = Color(0xFF1E2A3D);
const uiDarkOnPrimaryContainer = Color(0xFFE7EEFF);
const uiDarkSecondaryContainer = Color(0xFF25324A);
const uiDarkOnSecondaryContainer = Color(0xFFD9E4FF);
const uiDarkHeaderGradientStart = Color(0xFF1C2433);
const uiDarkHeaderGradientEnd = Color(0xFF232E42);
const uiDarkMetricSalary = Color(0xFF8FB8A4);
const uiDarkMetricLocation = Color(0xFF95A8C4);
const uiDarkMetricModality = Color(0xFFA3AFC2);
const uiDarkTagText = Color(0xFFB8C7E6);

// Dark Theme Card Gradients
const uiDarkCardGradientStart = Color(0xFF1E293B);
const uiDarkCardGradientEnd = Color(0xFF161E2E);

// Spacing
const double uiSpacing4 = 4.0;
const double uiSpacing8 = 8.0;
const double uiSpacing12 = 12.0;
const double uiSpacing16 = 16.0;
const double uiSpacing20 = 20.0;
const double uiSpacing24 = 24.0;
const double uiSpacing32 = 32.0;
const double uiSpacing48 = 48.0;

// Radius
const double uiCardRadius = 24.0;
const double uiTileRadius = 18.0;
const double uiFieldRadius = 14.0;
const double uiPillRadius = 999.0;

// Shadows
const List<BoxShadow> uiShadowSm = [
  BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
];

const List<BoxShadow> uiShadowMd = [
  BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  ),
  BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: -1,
  ),
];

// Durations
const uiDurationFast = Duration(milliseconds: 200);
const uiDurationNormal = Duration(milliseconds: 300);
const uiDurationSlow = Duration(milliseconds: 500);

// Breakpoints
const double uiBreakpointMobile = 600.0;
const double uiBreakpointTablet = 900.0;
const double uiBreakpointDesktop = 1200.0;
