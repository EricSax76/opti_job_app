import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_ai_consent_flow.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_knockout_flow.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_loading_dialog.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_pre_apply_verdict_dialog.dart';

class JobOfferDetailApplyFlow {
  const JobOfferDetailApplyFlow._();

  static Future<void> apply(
    BuildContext context,
    JobOfferApplyRequest? request,
  ) async {
    if (request == null) return;

    final outcome = await _evaluateBeforeApplying(context, request);
    if (!context.mounted) return;

    final shouldProceed = await _confirmApplyWithOutcome(context, outcome);
    if (shouldProceed != true || !context.mounted) return;

    final consentGranted = await JobOfferDetailAiConsentFlow.requestAiConsent(
      context,
      request,
    );
    if (!context.mounted || !consentGranted) return;

    final knockoutResponses = await JobOfferDetailKnockoutFlow.collectResponses(
      context,
      request.offer,
    );
    if (knockoutResponses == null || !context.mounted) return;

    await context.read<JobOfferDetailCubit>().apply(
      candidate: request.candidate,
      offer: request.offer,
      knockoutResponses: knockoutResponses,
    );
  }

  static Future<JobOfferMatchOutcome> _evaluateBeforeApplying(
    BuildContext context,
    JobOfferApplyRequest request,
  ) {
    return JobOfferDetailLoadingDialog.run<JobOfferMatchOutcome>(
      context: context,
      title: 'Evaluando encaje',
      message: 'Contrastando tu CV con esta oferta...',
      action: () =>
          context.read<JobOfferDetailCubit>().evaluateFitForApplication(
            candidateUid: request.candidate.uid,
            offer: request.offer,
          ),
    );
  }

  static Future<bool?> _confirmApplyWithOutcome(
    BuildContext context,
    JobOfferMatchOutcome outcome,
  ) {
    if (outcome is JobOfferMatchSuccess) {
      return showDialog<bool>(
        context: context,
        builder: (dialogContext) =>
            JobOfferPreApplyVerdictDialog(result: outcome.result),
      );
    }

    if (outcome is JobOfferMatchFailure) {
      return showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('No se pudo evaluar el encaje'),
            content: Text(
              '${outcome.message}\n\nPuedes continuar igualmente o cancelar la postulación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Continuar postulación'),
              ),
            ],
          );
        },
      );
    }

    return Future.value(false);
  }
}
