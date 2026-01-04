import 'package:flutter/material.dart';

class CompanyCandidatesHeader extends StatelessWidget {
  const CompanyCandidatesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'CANDIDATOS',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Postulaciones por oferta',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Expande una oferta para ver los candidatos que se han postulado.',
          style: TextStyle(color: muted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}

