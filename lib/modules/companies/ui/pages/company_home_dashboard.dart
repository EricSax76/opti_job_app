import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_home_dashboard_content.dart';

class CompanyHomeDashboard extends StatelessWidget {
  const CompanyHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyHomeDashboardContent(
      onLoadCandidates: () => _loadApplicantsForAllOffers(context),
    );
  }

  void _loadApplicantsForAllOffers(BuildContext context) {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;

    final offersState = context.read<CompanyJobOffersCubit>().state;
    final offers = offersState.offers;
    if (offers.isEmpty) return;

    context.read<OfferApplicantsCubit>().loadApplicantsForOffers(
      offerIds: offers.map((offer) => offer.id),
      companyUid: companyUid,
      force: true,
    );
  }
}
