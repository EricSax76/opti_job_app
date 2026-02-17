import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_detail_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/ui/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_match_dialog.dart';

class JobOfferDetailController {
  const JobOfferDetailController._();

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
      _showSnackBar(
        context,
        message: successMessage,
        backgroundColor: Colors.green,
      );
      context.read<JobOfferDetailCubit>().clearMessages();
      return;
    }

    final errorMessage = JobOfferDetailLogic.errorMessage(state);
    if (errorMessage == null) return;

    _showSnackBar(
      context,
      message: errorMessage,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    context.read<JobOfferDetailCubit>().clearMessages();
  }

  static void _handleMatchOutcome(
      BuildContext context, JobOfferMatchOutcome outcome) {
    if (outcome is JobOfferMatchSuccess) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) =>
            JobOfferMatchResultDialog(result: outcome.result),
      );
    } else if (outcome is JobOfferMatchFailure) {
      _showSnackBar(context, message: outcome.message);
    }
  }

  static Future<void> showMatchResult(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          title: Text('Calculando match'),
          content: Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Analizando tu CV contra la oferta...')),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    await context.read<JobOfferDetailCubit>().computeMatch();

    if (isLoadingDialogOpen && rootNavigator.mounted) {
      rootNavigator.pop();
    }
  }

  static void apply(BuildContext context, JobOfferApplyRequest? request) {
    if (request == null) return;

    context.read<JobOfferDetailCubit>().apply(
      candidate: request.candidate,
      offer: request.offer,
    );
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/job-offer');
  }


  static void _showSnackBar(
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
}
