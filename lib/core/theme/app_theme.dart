import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
      ).copyWith(onSurface: _ink, onSurfaceVariant: _muted),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: -1,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: const TextStyle(
          color: _muted,
        ),
      ),
    );
  }
}
