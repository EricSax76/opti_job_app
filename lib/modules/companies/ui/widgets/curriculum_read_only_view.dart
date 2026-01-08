import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumReadOnlyView extends StatelessWidget {
  const CurriculumReadOnlyView({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const border = Color(0xFFE2E8F0);
    const background = Color(0xFFF8FAFC);

    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    }

    Widget card({required Widget child}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (curriculum.headline.trim().isNotEmpty) ...[
          sectionTitle('Titular'),
          card(
            child: Text(
              curriculum.headline.trim(),
              style: const TextStyle(color: ink, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
        ],
        // ... (resto de secciones simplificadas para brevedad, siguen el mismo patrón)
        if (curriculum.experiences.isNotEmpty) ...[
          sectionTitle('Experiencia'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in curriculum.experiences)
                  _CurriculumItemBlock(item: item),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // ... otras secciones
      ],
    );
  }
}

class _CurriculumItemBlock extends StatelessWidget {
  const _CurriculumItemBlock({required this.item});
  final CurriculumItem item;
  @override
  Widget build(BuildContext context) {
    // Implementación simple del bloque de item
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (item.subtitle.isNotEmpty) Text(item.subtitle),
          if (item.description.isNotEmpty) Text(item.description),
        ],
      ),
    );
  }
}
