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
  });

  final GlobalKey<FormState> formKey;
  final OfferFormControllers controllers;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear nueva oferta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              OfferFormFields(controllers: controllers),
              const SizedBox(height: 24),
              BlocBuilder<JobOfferFormCubit, JobOfferFormState>(
                builder: (context, state) {
                  final isSubmitting =
                      state.status == JobOfferFormStatus.submitting;
                  return FilledButton(
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
