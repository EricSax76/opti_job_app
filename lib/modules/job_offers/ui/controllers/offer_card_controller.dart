import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/offer_card_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class OfferCardController {
  const OfferCardController._();

  static void onExpansionChanged(
    BuildContext context, {
    required bool expanded,
    required JobOffer offer,
    required String? companyUid,
  }) {
    final applicantsCubit = context.read<OfferApplicantsCubit>();
    final status =
        applicantsCubit.state.statuses[offer.id] ??
        OfferApplicantsStatus.initial;
    if (!OfferCardLogic.shouldLoadApplicants(
      expanded: expanded,
      status: status,
    )) {
      return;
    }

    final normalizedCompanyUid = OfferCardLogic.normalizeCompanyUid(companyUid);
    if (normalizedCompanyUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar el usuario de empresa.'),
        ),
      );
      return;
    }

    applicantsCubit.loadApplicants(
      offerId: offer.id,
      companyUid: normalizedCompanyUid,
    );
  }
}
