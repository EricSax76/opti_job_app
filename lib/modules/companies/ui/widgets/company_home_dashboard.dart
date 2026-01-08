import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard_candidates_card.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard_home_header.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard_offers_card.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';

class CompanyHomeDashboard extends StatefulWidget {
  const CompanyHomeDashboard({super.key});

  @override
  State<CompanyHomeDashboard> createState() => _CompanyHomeDashboardState();
}

class _CompanyHomeDashboardState extends State<CompanyHomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const DashboardHomeHeader(),
        const SizedBox(height: 16),
        DashboardOffersCard(
          onLoadCandidates: () => _loadApplicantsForAllOffers(context),
        ),
        const SizedBox(height: 12),
        DashboardCandidatesCard(
          onLoadCandidates: () => _loadApplicantsForAllOffers(context),
        ),
      ],
    );
  }

  void _loadApplicantsForAllOffers(BuildContext context) {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;

    final offersState = context.read<CompanyJobOffersCubit>().state;
    final offers = offersState.offers;
    if (offers.isEmpty) return;

    final applicantsCubit = context.read<OfferApplicantsCubit>();
    for (final offer in offers) {
      final status =
          applicantsCubit.state.statuses[offer.id] ??
          OfferApplicantsStatus.initial;
      if (status != OfferApplicantsStatus.loading) {
        applicantsCubit.loadApplicants(
          offerId: offer.id,
          companyUid: companyUid,
        );
      }
    }
  }
}
