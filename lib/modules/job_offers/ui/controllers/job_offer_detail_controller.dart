import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
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

  static Future<void> showMatchResult(
    BuildContext context, {
    required JobOfferMatchRequest request,
  }) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    void closeLoadingDialogIfNeeded() {
      if (!isLoadingDialogOpen || !rootNavigator.mounted) return;
      rootNavigator.pop();
      isLoadingDialogOpen = false;
    }

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

    final outcome = await JobOfferMatchLogic.computeMatch(
      curriculumRepository: context.read<CurriculumRepository>(),
      aiRepository: context.read<AiRepository>(),
      candidateUid: request.candidateUid,
      offer: request.offer,
    );
    if (!context.mounted) return;

    closeLoadingDialogIfNeeded();
    if (outcome is JobOfferMatchSuccess) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) =>
            JobOfferMatchResultDialog(result: outcome.result),
      );
      return;
    }

    if (outcome is JobOfferMatchFailure) {
      _showSnackBar(context, message: outcome.message);
    }
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
