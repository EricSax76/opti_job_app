import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/modules/ats/models/knockout_question.dart';
import 'package:opti_job_app/modules/ats/ui/widgets/knockout_questions_form.dart';
import 'package:opti_job_app/modules/ats/ui/widgets/pipeline_template_selector.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/offer_form_fields.dart';

class CreateOfferCard extends StatelessWidget {
  const CreateOfferCard({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.onSubmit,
    required this.onGenerateWithAi,
    required this.isGenerating,
    required this.onPipelineSelected,
    required this.onKnockoutQuestionsChanged,
  });

  final GlobalKey<FormState> formKey;
  final OfferFormControllers controllers;
  final VoidCallback onSubmit;
  final VoidCallback onGenerateWithAi;
  final bool isGenerating;
  final ValueChanged<String?> onPipelineSelected;
  final ValueChanged<List<KnockoutQuestion>> onKnockoutQuestionsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final muted = colorScheme.onSurfaceVariant;
    final ink = colorScheme.onSurface;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing24 + 4),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PUBLICAR',
              style: textTheme.labelSmall?.copyWith(
                color: muted,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crear nueva oferta',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa los datos principales y publícala para recibir postulaciones.',
              style: textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AiGeneratedLabel(compact: true),
                  const SizedBox(height: uiSpacing8),
                  Semantics(
                    button: true,
                    label: 'Generar borrador de oferta con IA',
                    hint:
                        'Crea un borrador inicial que debes revisar antes de publicar.',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      onPressed: isGenerating ? null : onGenerateWithAi,
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          isGenerating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          Text(isGenerating ? 'Generando...' : 'Generar con IA'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OfferFormFields(controllers: controllers),

            const Divider(height: uiSpacing32),

            // Integración ATS Module
            Text(
              'Ajustes del Applicant Tracking System (ATS)',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const SizedBox(height: uiSpacing16),
            PipelineTemplateSelector(onPipelineSelected: onPipelineSelected),
            const SizedBox(height: uiSpacing24),
            KnockoutQuestionsForm(
              initialQuestions: const [],
              onQuestionsChanged: onKnockoutQuestionsChanged,
            ),

            const SizedBox(height: 32),

            BlocBuilder<JobOfferFormCubit, JobOfferFormState>(
              builder: (context, state) {
                final isSubmitting =
                    state.status == JobOfferFormStatus.submitting;
                return SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Publicar oferta',
                    hint:
                        'Publica la oferta para abrir candidaturas en el sistema.',
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: uiSpacing12,
                        ),
                      ),
                      onPressed: isSubmitting ? null : onSubmit,
                      child: isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Publicar oferta'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
