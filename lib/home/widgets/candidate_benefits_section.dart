import 'package:flutter/material.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';

class CandidateBenefitsSection extends StatelessWidget {
  const CandidateBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficios para candidatos',
          style: const TextStyle(
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
            'Procesos más rápidos y sin fricciones',
          ],
        ),
      ],
    );
  }
}
