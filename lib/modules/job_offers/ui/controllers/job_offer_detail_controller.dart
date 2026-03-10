import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_apply_flow.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_feedback_handler.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_match_flow.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_signature_flow.dart';

class JobOfferDetailController {
  const JobOfferDetailController._();

  static void handleDetailMessages(
    BuildContext context,
    JobOfferDetailState state,
  ) {
    JobOfferDetailFeedbackHandler.handleDetailMessages(context, state);
  }

  static Future<void> showMatchResult(BuildContext context) {
    return JobOfferDetailMatchFlow.showMatchResult(context);
  }

  static Future<void> apply(
    BuildContext context,
    JobOfferApplyRequest? request,
  ) {
    return JobOfferDetailApplyFlow.apply(context, request);
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/job-offer');
  }

  static Future<void> signQualifiedOffer(
    BuildContext context, {
    required String applicationId,
  }) {
    return JobOfferDetailSignatureFlow.signQualifiedOffer(
      context,
      applicationId: applicationId,
    );
  }
}
