import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: Colors.indigo.shade900,
      child: Text(
        '© $currentYear OPTIJOB · Conectando talento con oportunidades',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
