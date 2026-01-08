import 'package:flutter/material.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';

class CandidateBenefitsSection extends StatelessWidget {
  const CandidateBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficios para candidatos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Recibe oportunidades diseñadas para tu perfil con una experiencia simple y directa.',
          style: TextStyle(color: muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        const HighlightList(
          items: [
            'Ofertas personalizadas según tus habilidades',
            'Recomendaciones inteligentes impulsadas por IA',
            'Procesos más rápidos',
          ],
        ),
      ],
    );
  }
}
