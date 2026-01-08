import 'package:flutter/material.dart';

const cvBackground = Color(0xFFF8FAFC);
const cvInk = Color(0xFF0F172A);
const cvMuted = Color(0xFF475569);
const cvBorder = Color(0xFFE2E8F0);
const cvAccent = Color(0xFF3FA7A0);

InputDecoration cvInputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: cvBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cvBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cvBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cvAccent),
    ),
  );
}
