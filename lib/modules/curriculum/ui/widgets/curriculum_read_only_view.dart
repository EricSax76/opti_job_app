import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_read_only_logic.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/curriculum_read_only_exports.dart';

class CurriculumReadOnlyView extends StatelessWidget {
  const CurriculumReadOnlyView({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    final viewModel = CurriculumReadOnlyLogic.buildViewModel(curriculum);

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.hasHeadline) ...[
            const CurriculumReadOnlySectionTitle(text: 'Titular'),
            CurriculumReadOnlyTextCard(
              text: viewModel.headline,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasSummary) ...[
            const CurriculumReadOnlySectionTitle(text: 'Resumen Profesional'),
            CurriculumReadOnlyTextCard(
              text: viewModel.summary,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasContactInfo) ...[
            const CurriculumReadOnlySectionTitle(
              text: 'Información de Contacto',
            ),
            CurriculumReadOnlyContactCard(viewModel: viewModel.contact),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasSkills) ...[
            const CurriculumReadOnlySectionTitle(
              text: 'Habilidades y Conocimientos',
            ),
            CurriculumReadOnlySkillsCard(skills: viewModel.skills),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasExperiences) ...[
            const CurriculumReadOnlySectionTitle(text: 'Experiencia Laboral'),
            CurriculumReadOnlyItemsCard(items: viewModel.experiences),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasEducation) ...[
            const CurriculumReadOnlySectionTitle(text: 'Formación Académica'),
            CurriculumReadOnlyItemsCard(items: viewModel.education),
            const SizedBox(height: uiSpacing24),
          ],
          if (viewModel.hasAttachment) ...[
            const CurriculumReadOnlySectionTitle(text: 'Curriculum Adjunto'),
            CurriculumReadOnlyAttachmentCard(
              fileName: viewModel.attachmentFileName!,
            ),
          ],
        ],
      ),
    );
  }
}
