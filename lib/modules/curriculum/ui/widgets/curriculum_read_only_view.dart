import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

class CurriculumReadOnlyView extends StatelessWidget {
  const CurriculumReadOnlyView({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    Widget sectionTitle(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: cvInk,
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
          color: cvBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cvBorder),
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
              style: const TextStyle(color: cvInk, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.summary.trim().isNotEmpty) ...[
          sectionTitle('Resumen'),
          card(
            child: Text(
              curriculum.summary.trim(),
              style: const TextStyle(color: cvInk, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.phone.trim().isNotEmpty ||
            curriculum.location.trim().isNotEmpty) ...[
          sectionTitle('Contacto'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (curriculum.phone.trim().isNotEmpty)
                  Text(
                    'Teléfono: ${curriculum.phone.trim()}',
                    style: const TextStyle(color: cvInk),
                  ),
                if (curriculum.location.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Ubicación: ${curriculum.location.trim()}',
                      style: const TextStyle(color: cvInk),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.skills.isNotEmpty) ...[
          sectionTitle('Skills'),
          card(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in curriculum.skills)
                  Chip(
                    label: Text(skill),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: cvBorder),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
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
        if (curriculum.education.isNotEmpty) ...[
          sectionTitle('Educación'),
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in curriculum.education)
                  _CurriculumItemBlock(item: item),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (curriculum.attachment != null) ...[
          sectionTitle('Adjunto'),
          card(
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: cvMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    curriculum.attachment!.fileName,
                    style: const TextStyle(color: cvInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CurriculumItemBlock extends StatelessWidget {
  const _CurriculumItemBlock({required this.item});

  final CurriculumItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.subtitle),
          ],
          if (item.period.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.period, style: const TextStyle(color: cvMuted)),
          ],
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.description),
          ],
        ],
      ),
    );
  }
}
