import 'package:flutter/material.dart';

class CompanyDashboardHeader extends StatelessWidget {
  const CompanyDashboardHeader({super.key, required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EMPRESAS',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hola, $companyName',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Publica nuevas vacantes y gestiona tus ofertas fácilmente.',
          style: TextStyle(color: muted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
