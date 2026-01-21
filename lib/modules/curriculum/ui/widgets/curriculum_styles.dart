import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

const cvBackground = uiBackground;
const cvInk = uiInk;
const cvMuted = uiMuted;
const cvBorder = uiBorder;
const cvAccent = uiAccent;

InputDecoration cvInputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: cvBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(uiFieldRadius),
      borderSide: const BorderSide(color: cvBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(uiFieldRadius),
      borderSide: const BorderSide(color: cvBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(uiFieldRadius),
      borderSide: const BorderSide(color: cvAccent),
    ),
  );
}
