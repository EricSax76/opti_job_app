import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offer_form_controllers.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offer_form_fields.dart';

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
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PUBLICAR',
              style: TextStyle(
                color: muted,
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
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completa los datos principales y publícala para recibir postulaciones.',
              style: TextStyle(color: muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isGenerating ? null : onGenerateWithAi,
                icon: isGenerating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(isGenerating ? 'Generando...' : 'Generar con IA'),
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
                      backgroundColor: ink,
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
