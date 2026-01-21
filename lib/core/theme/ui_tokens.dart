import 'package:flutter/material.dart';

// Colors
const uiInk = Color(0xFF0F172A);
const uiMuted = Color(0xFF475569);
const uiBorder = Color(0xFFE2E8F0);
const uiBackground = Color(0xFFF8FAFC);
const uiAccent = Color(0xFF3FA7A0);
const uiAccentSoft = Color(0xFFF1F7F6);
const uiError = Color(0xFFEF4444);
const uiSuccess = Color(0xFF10B981);
const uiWhite = Colors.white;

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
  BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  ),
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
