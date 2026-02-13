import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/modern_job_offer_card.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

const double _dashboardPaginationThreshold = 280;

class DashboardOffersSection extends StatelessWidget {
  const DashboardOffersSection({super.key, required this.showTwoColumns});

  final bool showTwoColumns;

  @override
  Widget build(BuildContext context) {
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
          previous.activeFilters != current.activeFilters,
      builder: (context, state) {
        final offers = state.displayedOffers
            .where((offer) => !appliedOfferIds.contains(offer.id))
            .toList(growable: false);
        return _DashboardOffersGrid(
          state: state,
          offers: offers,
          showTwoColumns: showTwoColumns,
        );
      },
    );
  }
}

class _DashboardOffersGrid extends StatelessWidget {
  const _DashboardOffersGrid({
    required this.state,
    required this.offers,
    required this.showTwoColumns,
  });

  final JobOffersState state;
  final List<JobOffer> offers;
  final bool showTwoColumns;

  @override
  Widget build(BuildContext context) {
    if (state.status == JobOffersStatus.loading ||
        state.status == JobOffersStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOffersStatus.failure) {
      return StateMessage(
        title: 'No se pudieron cargar las ofertas',
        message: state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
        actionLabel: 'Reintentar',
        onAction: () =>
            context.read<JobOffersCubit>().loadOffers(forceRefresh: true),
      );
    }

    if (offers.isEmpty) {
      final hasFilters = state.activeFilters.hasActiveFilters;
      return StateMessage(
        title: hasFilters ? 'Sin resultados' : 'Sin ofertas disponibles',
        message: hasFilters
            ? 'No se encontraron ofertas con los filtros aplicados.'
            : 'Aún no hay ofertas disponibles. Intenta más tarde.',
        actionLabel: hasFilters ? 'Limpiar filtros' : 'Actualizar',
        onAction: hasFilters
            ? () => context.read<JobOffersCubit>().clearFilters()
            : () =>
                context.read<JobOffersCubit>().loadOffers(forceRefresh: true),
      );
    }

    if (showTwoColumns) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
          final grid = NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _handleScroll(context, notification),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 190,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: offers.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) =>
                  _buildOfferCard(context, offers[index], index, isGrid: true),
            ),
          );
          if (!state.isLoadingMore) return grid;
          return _LoadingMoreOverlay(child: grid);
        },
      );
    }

    final list = NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleScroll(context, notification),
      child: ListView.builder(
        itemCount: offers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildOfferCard(
              context,
              offers[index],
              index,
              isGrid: false,
            ),
          );
        },
      ),
    );
    if (!state.isLoadingMore) return list;
    return _LoadingMoreOverlay(child: list);
  }

  Widget _buildOfferCard(
    BuildContext context,
    JobOffer offer,
    int index, {
    required bool isGrid,
  }) {
    final company = offer.companyId == null
        ? null
        : state.companiesById[offer.companyId!];
    return ModernJobOfferCard(
      title: offer.title,
      company: offer.companyName ?? company?.name ?? 'Empresa no especificada',
      description: offer.description,
      avatarUrl: offer.companyAvatarUrl ?? company?.avatarUrl,
      salary: offer.formattedSalary,
      location: offer.location,
      modality: offer.jobType ?? 'Modalidad no especificada',
      tags: _extractTags(offer),
      heroTag: '${isGrid ? 'offers-grid' : 'offers-list'}-$index-${offer.id}',
      onTap: () => context.push('/job-offer/${offer.id}'),
    );
  }

  List<String>? _extractTags(JobOffer offer) {
    final tags = <String>[];
    if (offer.education != null && offer.education!.isNotEmpty) {
      tags.add(offer.education!);
    }
    if (offer.keyIndicators != null && offer.keyIndicators!.isNotEmpty) {
      final indicators = offer.keyIndicators!.split(',');
      tags.addAll(indicators.take(2).map((value) => value.trim()));
    }
    return tags.isEmpty ? null : tags;
  }

  bool _handleScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final distanceToBottom =
        notification.metrics.maxScrollExtent - notification.metrics.pixels;
    if (distanceToBottom <= _dashboardPaginationThreshold &&
        state.hasMore &&
        !state.isLoadingMore &&
        !state.isRefreshing &&
        state.status == JobOffersStatus.success) {
      context.read<JobOffersCubit>().loadMoreOffers();
    }
    return false;
  }
}

class _LoadingMoreOverlay extends StatelessWidget {
  const _LoadingMoreOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}
