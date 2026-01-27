import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class AppButtonTheme {
  static final FilledButtonThemeData filledButtonTheme =
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: uiInk,
          foregroundColor: uiWhite,
          minimumSize: const Size.fromHeight(52),
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
      );

  static final OutlinedButtonThemeData outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: uiInk,
          side: const BorderSide(color: uiBorder),
          minimumSize: const Size.fromHeight(52),
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
      );

  static final TextButtonThemeData textButtonTheme = TextButtonThemeData(
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
  );

  // Helper styles for variants
  static final ButtonStyle primaryFilled = FilledButton.styleFrom(
    backgroundColor: uiInk,
    foregroundColor: uiWhite,
  );

  static final ButtonStyle secondaryFilled = FilledButton.styleFrom(
    backgroundColor: uiAccent,
    foregroundColor: uiWhite,
  );

  static final ButtonStyle dangerFilled = FilledButton.styleFrom(
    backgroundColor: uiError,
    foregroundColor: uiWhite,
  );

  static final ButtonStyle dangerOutlined = OutlinedButton.styleFrom(
    foregroundColor: uiError,
    side: const BorderSide(color: uiError),
  );
}
