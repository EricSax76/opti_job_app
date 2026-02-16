import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/read_only/curriculum_read_only_sections.dart';

class CurriculumReadOnlyView extends StatelessWidget {
  const CurriculumReadOnlyView({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (curriculum.headline.trim().isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(text: 'Titular'),
            CurriculumReadOnlyTextCard(
              text: curriculum.headline.trim(),
              style: const TextStyle(
                color: uiInk,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.summary.trim().isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(text: 'Resumen Profesional'),
            CurriculumReadOnlyTextCard(
              text: curriculum.summary.trim(),
              style: const TextStyle(color: uiInk, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.phone.trim().isNotEmpty ||
              curriculum.location.trim().isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(
              text: 'Información de Contacto',
            ),
            CurriculumReadOnlyContactCard(
              phone: curriculum.phone,
              location: curriculum.location,
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.skills.isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(
              text: 'Habilidades y Conocimientos',
            ),
            CurriculumReadOnlySkillsCard(skills: curriculum.skills),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.experiences.isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(text: 'Experiencia Laboral'),
            CurriculumReadOnlyItemsCard(items: curriculum.experiences),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.education.isNotEmpty) ...[
            const CurriculumReadOnlySectionTitle(text: 'Formación Académica'),
            CurriculumReadOnlyItemsCard(items: curriculum.education),
            const SizedBox(height: uiSpacing24),
          ],
          if (curriculum.attachment != null) ...[
            const CurriculumReadOnlySectionTitle(text: 'Curriculum Adjunto'),
            CurriculumReadOnlyAttachmentCard(
              fileName: curriculum.attachment!.fileName,
            ),
          ],
        ],
      ),
    );
  }
}
