import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Text(
        '© $currentYear OPTIJOB · Conectando talento con oportunidades',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
    );
  }
}
