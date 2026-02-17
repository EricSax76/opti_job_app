import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_list_logic.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/job_offer_list_controller.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/list/job_offer_list_content.dart';

class JobOfferListContainer extends StatefulWidget {
  const JobOfferListContainer({super.key});

  @override
  State<JobOfferListContainer> createState() => _JobOfferListContainerState();
}

class _JobOfferListContainerState extends State<JobOfferListContainer> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<JobOffersCubit>();
    if (JobOfferListLogic.shouldLoadInitialOffers(cubit.state)) {
      cubit.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobOffersCubit, JobOffersState>(
      listenWhen: (previous, current) =>
          JobOfferListLogic.shouldShowRefreshError(
            previous: previous,
            current: current,
          ),
      listener: JobOfferListController.showRefreshErrorMessage,
      builder: (context, state) {
        final cubit = context.read<JobOffersCubit>();

        if (state.status == JobOffersStatus.initial ||
            state.status == JobOffersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == JobOffersStatus.failure) {
          return StateMessage(
            title: 'Error',
            message: state.errorMessage ?? 'Error al cargar las ofertas.',
            actionLabel: 'Reintentar',
            onAction: () => cubit.retry(),
          );
        }

        final viewModel = JobOfferListLogic.buildViewModel(state);
        return JobOfferListContent(
          viewModel: viewModel,
          onSelectJobType: cubit.selectJobType,
          onClearJobType: () => cubit.selectJobType(null),
          onShowAllOffers: () => cubit.selectJobType(null),
          onLoadMore: cubit.loadMoreOffers,
          onOpenOffer: (offerId) => context.push('/job-offer/$offerId'),
        );
      },
    );
  }
}
