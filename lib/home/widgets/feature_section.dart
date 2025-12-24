import 'package:flutter/material.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimización con IA',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Los algoritmos analizan perfiles, automatizan entrevistas y encuentran el mejor match en segundos.',
          style: const TextStyle(color: muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        const HighlightList(
          items: [
            'Analiza perfiles de candidatos instantáneamente',
            'Automatiza la programación de entrevistas',
            'Identifica el mejor ajuste basado en datos',
          ],
        ),
      ],
    );
  }
}
