import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_detail_logic.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/job_offer_detail_controller.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/detail/job_offer_detail_content.dart';

class JobOfferDetailContainer extends StatelessWidget {
  const JobOfferDetailContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    final companiesById = context.select<JobOffersCubit, Map<int, Company>>(
      (cubit) => cubit.state.companiesById,
    );

    return BlocListener<JobOfferDetailCubit, JobOfferDetailState>(
      listenWhen: (previous, current) =>
          JobOfferDetailLogic.shouldListenForMessages(
            previous: previous,
            current: current,
          ),
      listener: JobOfferDetailController.handleDetailMessages,
      child: BlocBuilder<JobOfferDetailCubit, JobOfferDetailState>(
        builder: (context, state) {
          final viewModel = JobOfferDetailLogic.buildViewModel(
            state: state,
            isAuthenticated: authState.isAuthenticated,
            candidate: authState.candidate,
            companiesById: companiesById,
          );
          final matchRequest = viewModel.matchRequest;

          return JobOfferDetailContent(
            state: viewModel.state,
            isAuthenticated: viewModel.isAuthenticated,
            companyAvatarUrl: viewModel.companyAvatarUrl,
            onApply: () =>
                JobOfferDetailController.apply(context, viewModel.applyRequest),
            onMatch: matchRequest == null
                ? null
                : () => JobOfferDetailController.showMatchResult(context),
            onBack: () => JobOfferDetailController.navigateBack(context),
          );
        },
      ),
    );
  }
}
