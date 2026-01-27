import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class AppInputTheme {
  static final InputDecorationTheme theme = InputDecorationTheme(
    filled: true,
    fillColor: uiBackground,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: uiSpacing16,
      vertical: uiSpacing16,
    ),
    labelStyle: const TextStyle(color: uiMuted, fontSize: 15),
    floatingLabelStyle: const TextStyle(color: uiAccent, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(uiFieldRadius),
      borderSide: const BorderSide(color: uiBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(uiFieldRadius),
      borderSide: const BorderSide(color: uiBorder),
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
  );

  // For specific success state handled manually in widgets
  static InputDecoration successDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      suffixIcon: suffixIcon ?? const Icon(Icons.check_circle, color: uiSuccess),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiSuccess),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiSuccess, width: 2),
      ),
    );
  }
}
