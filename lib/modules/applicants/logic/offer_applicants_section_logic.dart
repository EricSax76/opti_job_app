import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/applicants/cubits/applicant_interaction_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/models/offer_applicants_section_view_model.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';

class OfferApplicantsSectionLogic {
  const OfferApplicantsSectionLogic._();

  static bool shouldRebuildOfferApplicants({
    required OfferApplicantsState previous,
    required OfferApplicantsState current,
    required String offerId,
  }) {
    final previousStatus =
        previous.statuses[offerId] ?? OfferApplicantsStatus.initial;
    final currentStatus =
        current.statuses[offerId] ?? OfferApplicantsStatus.initial;
    final previousApplicants = previous.applicants[offerId];
    final currentApplicants = current.applicants[offerId];
    final previousError = previous.errors[offerId];
    final currentError = current.errors[offerId];

    return previousStatus != currentStatus ||
        previousApplicants != currentApplicants ||
        previousError != currentError;
  }

  static OfferApplicantsSectionViewModel buildViewModel({
    required OfferApplicantsState state,
    required String offerId,
  }) {
    return OfferApplicantsSectionViewModel(
      status: state.statuses[offerId] ?? OfferApplicantsStatus.initial,
      applicants: state.applicants[offerId] ?? const <Application>[],
      errorMessage: state.errors[offerId],
    );
  }

  static Future<void> requestInterviewStart({
    required BuildContext context,
    required ApplicantInteractionCubit interactionCubit,
    required String applicationId,
  }) async {
    final shouldStart = await _confirmInterviewStart(context);
    if (!context.mounted || shouldStart != true) return;
    await interactionCubit.startInterview(applicationId);
  }

  static void handleInteractionState(
    BuildContext context,
    ApplicantInteractionState state,
  ) {
    if (state is ApplicantInteractionSuccess) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      context.pushNamed(
        'interview-chat',
        pathParameters: {'id': state.interviewId},
      );
      return;
    }
    if (state is ApplicantInteractionFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
      return;
    }
    if (state is ApplicantInteractionLoading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Iniciando entrevista...')));
    }
  }

  static Future<bool?> _confirmInterviewStart(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Iniciar entrevista'),
        content: const Text(
          'Esto creará una sala de chat con el candidato. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
}
