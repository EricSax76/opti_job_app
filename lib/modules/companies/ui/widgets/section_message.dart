import 'package:flutter/material.dart';

class SectionMessage extends StatelessWidget {
  const SectionMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const muted = Color(0xFF475569);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Text(text, style: const TextStyle(color: muted, height: 1.4)),
    );
  }
}
