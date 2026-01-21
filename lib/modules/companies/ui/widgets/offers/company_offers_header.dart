import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CompanyOffersHeader extends StatelessWidget {
  const CompanyOffersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = uiInk;
    const muted = uiMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'OFERTAS',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Mis ofertas publicadas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ],
    );
  }
}
