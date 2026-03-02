import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/cubits/company_candidates_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_header.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_section.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyCandidatesTab extends StatelessWidget {
  const CompanyCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompanyCandidatesCubit(
        profileRepository: context.read<ProfileRepository>(),
        offerApplicantsCubit: context.read<OfferApplicantsCubit>(),
        companyJobOffersCubit: context.read<CompanyJobOffersCubit>(),
        companyAuthCubit: context.read<CompanyAuthCubit>(),
      )..start(),
      child: const CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              uiSpacing24,
              uiSpacing24,
              uiSpacing24,
              0,
            ),
            sliver: SliverToBoxAdapter(child: CompanyCandidatesHeader()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: uiSpacing12)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              uiSpacing24,
              0,
              uiSpacing24,
              uiSpacing32,
            ),
            sliver: CompanyCandidatesSection(),
          ),
        ],
      ),
    );
  }
}
