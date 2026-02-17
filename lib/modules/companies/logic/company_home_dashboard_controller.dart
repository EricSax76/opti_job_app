import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class CompanyHomeDashboardController {
  const CompanyHomeDashboardController._();

  static Future<void> loadApplicantsForAllOffers(BuildContext context) async {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;

    final offers = context.read<CompanyJobOffersCubit>().state.offers;
    if (offers.isEmpty) return;

    await context.read<OfferApplicantsCubit>().loadApplicantsForOffers(
      offerIds: offers.map((offer) => offer.id),
      companyUid: companyUid,
      force: true,
    );
  }
}
