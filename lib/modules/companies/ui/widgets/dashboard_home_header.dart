import 'package:flutter/material.dart';

class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'HOME',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Resumen rápido de tus ofertas y candidatos.',
          style: TextStyle(color: muted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
