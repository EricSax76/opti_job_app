import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
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
  });

  final GlobalKey<FormState> formKey;
  final OfferFormControllers controllers;
  final VoidCallback onSubmit;
  final VoidCallback onGenerateWithAi;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(uiCardRadius),
        border: Border.all(color: uiBorder),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PUBLICAR',
              style: TextStyle(
                color: uiMuted,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Crear nueva oferta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: uiInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa los datos principales y publícala para recibir postulaciones.',
              style: TextStyle(color: uiMuted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isGenerating ? null : onGenerateWithAi,
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    isGenerating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    Text(isGenerating ? 'Generando...' : 'Generar con IA'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OfferFormFields(controllers: controllers),
            const SizedBox(height: 20),
            BlocBuilder<JobOfferFormCubit, JobOfferFormState>(
              builder: (context, state) {
                final isSubmitting =
                    state.status == JobOfferFormStatus.submitting;
                return SizedBox(
                  width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: uiInk,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    onPressed: isSubmitting ? null : onSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Publicar oferta'),
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
