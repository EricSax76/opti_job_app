import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/app_button_theme.dart';
import 'package:opti_job_app/core/theme/app_input_theme.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: uiAccent).copyWith(
      surface: uiWhite,
      surfaceContainerHighest: uiBackground,
      onSurface: uiInk,
      onSurfaceVariant: uiMuted,
      primary: uiInk,
      secondary: uiAccent,
      error: uiError,
      outline: uiBorder,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: uiBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: uiWhite,
      foregroundColor: uiInk,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: AppInputTheme.theme,
    filledButtonTheme: AppButtonTheme.filledButtonTheme,
    outlinedButtonTheme: AppButtonTheme.outlinedButtonTheme,
    textButtonTheme: AppButtonTheme.textButtonTheme,
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        color: uiInk,
        fontWeight: FontWeight.w900,
        fontSize: 24,
        letterSpacing: -1,
      ),
      titleMedium: const TextStyle(color: uiInk, fontWeight: FontWeight.bold),
      bodyMedium: const TextStyle(color: uiMuted),
    ),
    cardTheme: CardThemeData(
      color: uiWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiCardRadius),
        side: BorderSide(color: uiBorder),
      ),
    ),
  );
}
