import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_grid.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';

class DashboardOffersSection extends StatelessWidget {
  const DashboardOffersSection({super.key, required this.showTwoColumns});

  final bool showTwoColumns;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JobOffersCubit>();
    final appliedOfferIds = context.select<MyApplicationsCubit, Set<String>>(
      (cubit) => cubit.state.applications
          .map((entry) => entry.application.jobOfferId)
          .toSet(),
    );

    return BlocBuilder<JobOffersCubit, JobOffersState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.offers != current.offers ||
          previous.filteredOffers != current.filteredOffers ||
          previous.companiesById != current.companiesById ||
          previous.errorMessage != current.errorMessage ||
          previous.activeFilters != current.activeFilters ||
          previous.isLoadingMore != current.isLoadingMore,
      builder: (context, state) {
        final offers = state.displayedOffers
            .where((offer) => !appliedOfferIds.contains(offer.id))
            .toList(growable: false);

        return DashboardOffersGrid(
          status: state.status.name, // Using status name as string
          offers: offers,
          companiesById: state.companiesById,
          showTwoColumns: showTwoColumns,
          isLoadingMore: state.isLoadingMore,
          hasMore: state.hasMore,
          hasActiveFilters: state.activeFilters.hasActiveFilters,
          errorMessage: state.errorMessage,
          onRetry: () => cubit.loadOffers(forceRefresh: true),
          onClearFilters: () => cubit.clearFilters(),
          onLoadMore: () => cubit.loadMoreOffers(),
          onOfferTap: (offer) => context.push('/job-offer/${offer.id}'),
        );
      },
    );
  }
}
