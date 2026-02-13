import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: uiAccent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: uiDarkSurface,
      surfaceContainerHighest: uiDarkSurfaceLight,
      onSurface: uiDarkInk,
      onSurfaceVariant: uiDarkMuted,
      primary: uiAccent,
      secondary: uiAccent,
      error: uiError,
      outline: uiDarkBorder,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: uiDarkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: uiDarkBackground,
      foregroundColor: uiDarkInk,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: uiDarkSurface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: uiSpacing16,
        vertical: uiSpacing16,
      ),
      labelStyle: const TextStyle(color: uiDarkMuted, fontSize: 15),
      floatingLabelStyle: const TextStyle(color: uiAccent, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiDarkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiDarkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiError, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: uiAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(uiFieldRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: uiSpacing24,
          vertical: uiSpacing16,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: uiDarkInk,
        side: const BorderSide(color: uiDarkBorder),
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(uiFieldRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: uiSpacing24,
          vertical: uiSpacing16,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: uiAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(uiFieldRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        color: uiDarkInk,
        fontWeight: FontWeight.w900,
        fontSize: 24,
        letterSpacing: -1,
      ),
      titleMedium: const TextStyle(
        color: uiDarkInk,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: const TextStyle(color: uiDarkMuted),
    ),
    cardTheme: CardThemeData(
      color: uiDarkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiCardRadius),
        side: BorderSide(color: uiDarkBorder),
      ),
    ),
  );
}
