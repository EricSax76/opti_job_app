import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_detail_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_match_dialog.dart';

class JobOfferDetailFeedbackHandler {
  const JobOfferDetailFeedbackHandler._();

  static void handleDetailMessages(
    BuildContext context,
    JobOfferDetailState state,
  ) {
    if (state.matchOutcome != null) {
      _handleMatchOutcome(context, state.matchOutcome!);
      context.read<JobOfferDetailCubit>().clearMatchOutcome();
      return;
    }

    final successMessage = JobOfferDetailLogic.successMessage(state);
    if (successMessage != null) {
      showSnackBar(
        context,
        message: successMessage,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
      context.read<JobOfferDetailCubit>().clearMessages();
      return;
    }

    final errorMessage = JobOfferDetailLogic.errorMessage(state);
    if (errorMessage == null) return;

    showSnackBar(
      context,
      message: errorMessage,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    context.read<JobOfferDetailCubit>().clearMessages();
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
  }

  static void _handleMatchOutcome(
    BuildContext context,
    JobOfferMatchOutcome outcome,
  ) {
    if (outcome is JobOfferMatchSuccess) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) =>
            JobOfferMatchResultDialog(result: outcome.result),
      );
      return;
    }

    if (outcome is JobOfferMatchFailure) {
      showSnackBar(context, message: outcome.message);
    }
  }
}
