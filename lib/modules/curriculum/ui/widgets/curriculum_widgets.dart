import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_header_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_items_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_personal_info_form.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_skills_section.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_state_message.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

class CandidateCurriculumView extends StatelessWidget {
  const CandidateCurriculumView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CurriculumFormCubit(curriculumCubit: context.read<CurriculumCubit>()),
      child: const _CandidateCurriculumContent(),
    );
  }
}

class _CandidateCurriculumContent extends StatelessWidget {
  const _CandidateCurriculumContent();

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<CurriculumFormCubit>();

    return BlocConsumer<CurriculumFormCubit, CurriculumFormState>(
      listener: (context, state) {
        if (state.notice != null && state.noticeMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
          formCubit.clearNotice();
        }
      },
      builder: (context, state) {
        if (state.viewStatus == CurriculumFormViewStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.viewStatus == CurriculumFormViewStatus.error) {
          return CurriculumStateMessage(
            title: 'No pudimos cargar tu curriculum',
            message:
                state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
            actionLabel: 'Reintentar',
            onAction: formCubit.refresh,
          );
        }

        if (state.viewStatus == CurriculumFormViewStatus.empty) {
          return const CurriculumStateMessage(
            title: 'Inicia sesión para ver tu curriculum',
            message: 'Necesitas una cuenta activa para editar tu CV.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cvBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurriculumHeaderSection(isSaving: state.isSaving),
                    const SizedBox(height: 20),
                    CurriculumPersonalInfoForm(state: state),
                    const SizedBox(height: 20),
                    CurriculumSkillsSection(skills: state.skills),
                    const SizedBox(height: 20),
                    CurriculumItemsSection(
                      title: 'Experiencia',
                      items: state.experiences,
                      emptyHint: 'Agrega tu experiencia laboral más relevante.',
                      onAdd: () async {
                        final created = await showCurriculumItemDialog(context);
                        if (created != null) formCubit.addExperience(created);
                      },
                      onEdit: (index, item) async {
                        final updated = await showCurriculumItemDialog(
                          context,
                          initial: item,
                        );
                        if (updated != null) {
                          formCubit.updateExperience(index, updated);
                        }
                      },
                      onRemove: formCubit.removeExperience,
                    ),
                    const SizedBox(height: 20),
                    CurriculumItemsSection(
                      title: 'Educación',
                      items: state.education,
                      emptyHint:
                          'Agrega tu formación académica o cursos clave.',
                      onAdd: () async {
                        final created = await showCurriculumItemDialog(context);
                        if (created != null) formCubit.addEducation(created);
                      },
                      onEdit: (index, item) async {
                        final updated = await showCurriculumItemDialog(
                          context,
                          initial: item,
                        );
                        if (updated != null) {
                          formCubit.updateEducation(index, updated);
                        }
                      },
                      onRemove: formCubit.removeEducation,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cvInk,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: state.canSubmit ? formCubit.submit : null,
                        child: state.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Guardar curriculum'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
