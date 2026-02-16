import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_header_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_items_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_personal_info_form.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_skills_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/editor/curriculum_save_button.dart';

class CurriculumEditorFormLayout extends StatelessWidget {
  const CurriculumEditorFormLayout({
    super.key,
    required this.state,
    required this.onSubmit,
    required this.onAddExperience,
    required this.onEditExperience,
    required this.onRemoveExperience,
    required this.onAddEducation,
    required this.onEditEducation,
    required this.onRemoveEducation,
  });

  final CurriculumFormState state;
  final VoidCallback onSubmit;
  final Future<void> Function() onAddExperience;
  final Future<void> Function(int index, CurriculumItem item) onEditExperience;
  final void Function(int index) onRemoveExperience;
  final Future<void> Function() onAddEducation;
  final Future<void> Function(int index, CurriculumItem item) onEditEducation;
  final void Function(int index) onRemoveEducation;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: uiSpacing16,
          vertical: uiSpacing24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              padding: const EdgeInsets.all(uiSpacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CurriculumHeaderSection(isSaving: state.isSaving),
                  const Divider(height: uiSpacing48),
                  CurriculumPersonalInfoForm(state: state),
                  const SizedBox(height: uiSpacing32),
                  CurriculumSkillsSection(skills: state.skills),
                  const SizedBox(height: uiSpacing32),
                  CurriculumItemsSection(
                    title: 'Experiencia',
                    items: state.experiences,
                    emptyHint: 'Agrega tu experiencia laboral más relevante.',
                    onAdd: () {
                      onAddExperience();
                    },
                    onEdit: onEditExperience,
                    onRemove: onRemoveExperience,
                  ),
                  const SizedBox(height: uiSpacing32),
                  CurriculumItemsSection(
                    title: 'Educación',
                    items: state.education,
                    emptyHint: 'Agrega tu formación académica o cursos clave.',
                    onAdd: () {
                      onAddEducation();
                    },
                    onEdit: onEditEducation,
                    onRemove: onRemoveEducation,
                  ),
                  const SizedBox(height: uiSpacing48),
                  CurriculumSaveButton(
                    enabled: state.canSubmit,
                    isSaving: state.isSaving,
                    onPressed: onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
