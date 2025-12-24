import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_detail_widgets.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';

class JobOfferDetailScreen extends StatelessWidget {
  const JobOfferDetailScreen({super.key, required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;

    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocListener<JobOfferDetailCubit, JobOfferDetailState>(
          listener: (context, state) {
            handleJobOfferDetailMessages(context, state);
          },
          child: BlocBuilder<JobOfferDetailCubit, JobOfferDetailState>(
            builder: (context, state) {
              return JobOfferDetailBody(state: state, authState: authState);
            },
          ),
        ),
      ),
    );
  }
}
