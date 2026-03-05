import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.focusModeEnabled = false,
  });

  final ThemeMode themeMode;
  final bool focusModeEnabled;

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? focusModeEnabled,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
    );
  }
}
