import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_interaction_cubit.dart';
import 'package:opti_job_app/modules/applicants/logic/offer_applicants_section_logic.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_header.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_section.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

class CompanyOffersTab extends StatelessWidget {
  const CompanyOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ApplicantInteractionCubit(context.read<InterviewRepository>()),
      child: BlocListener<ApplicantInteractionCubit, ApplicantInteractionState>(
        listener: OfferApplicantsSectionLogic.handleInteractionState,
        child: const CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                uiSpacing24,
                uiSpacing24,
                uiSpacing24,
                0,
              ),
              sliver: SliverToBoxAdapter(child: CompanyOffersHeader()),
            ),
            SliverToBoxAdapter(child: SizedBox(height: uiSpacing12)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                uiSpacing24,
                0,
                uiSpacing24,
                uiSpacing32,
              ),
              sliver: CompanyOffersSection(),
            ),
          ],
        ),
      ),
    );
  }
}
