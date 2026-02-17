import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/dashboard_offers_section_logic.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_grid.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';

class DashboardOffersSection extends StatelessWidget {
  const DashboardOffersSection({super.key, required this.showTwoColumns});

  final bool showTwoColumns;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JobOffersCubit>();
    final appliedOfferIds = context.select<MyApplicationsCubit, Set<String>>(
      (applicationsCubit) => DashboardOffersSectionLogic.resolveAppliedOfferIds(
        applicationsCubit.state,
      ),
    );

    return BlocBuilder<JobOffersCubit, JobOffersState>(
      buildWhen: DashboardOffersSectionLogic.shouldRebuild,
      builder: (context, state) {
        final viewModel = DashboardOffersSectionLogic.buildViewModel(
          state: state,
          appliedOfferIds: appliedOfferIds,
        );
        const allowedStatuses = {'initial', 'loading', 'failure', 'success'};
        if (!allowedStatuses.contains(viewModel.status)) {
          return const StateMessage(
            title: 'Estado de ofertas no soportado',
            message:
                'No se pudo renderizar el tablero de ofertas. Intenta refrescar.',
          );
        }

        return DashboardOffersGrid(
          status: viewModel.status,
          offers: viewModel.offers,
          companiesById: viewModel.companiesById,
          showTwoColumns: showTwoColumns,
          isLoadingMore: viewModel.isLoadingMore,
          hasMore: viewModel.hasMore,
          hasActiveFilters: viewModel.hasActiveFilters,
          errorMessage: viewModel.errorMessage,
          onRetry: cubit.refresh,
          onClearFilters: () => cubit.clearFilters(),
          onLoadMore: () => cubit.loadMoreOffers(),
          onOfferTap: (offer) => context.push('/job-offer/${offer.id}'),
        );
      },
    );
  }
}
