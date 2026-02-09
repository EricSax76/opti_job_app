import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/modern_job_offer_card.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/calendar_panel.dart';

const double _dashboardPaginationThreshold = 280;

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCandidateName = context.select<ProfileCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final authCandidateName = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final candidateName =
        profileCandidateName ?? authCandidateName ?? 'Candidato';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 600;

        return Row(
          children: [
            if (showSidebar) const _DashboardFiltersSidebar(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $candidateName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Aquí tienes ofertas seleccionadas para ti.'),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _OffersSection(showTwoColumns: showSidebar),
                          ),
                          const SizedBox(height: 16),
                          const _DashboardCalendarPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardFiltersSidebar extends StatelessWidget {
  const _DashboardFiltersSidebar();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
      selector: (state) => state.activeFilters,
      builder: (context, filters) {
        return JobOfferFilterSidebar(
          currentFilters: filters,
          onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
        );
      },
    );
  }
}

class _DashboardCalendarPanel extends StatelessWidget {
  const _DashboardCalendarPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) => CalendarPanel(state: state),
    );
  }
}

class _OffersSection extends StatelessWidget {
  const _OffersSection({required this.showTwoColumns});

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
        return _OffersGrid(
          state: state,
          offers: offers,
          showTwoColumns: showTwoColumns,
        );
      },
    );
  }
}

class _OffersGrid extends StatelessWidget {
  const _OffersGrid({
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
      return Center(
        child: Text(state.errorMessage ?? 'Error al cargar las ofertas.'),
      );
    }

    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              state.activeFilters.hasActiveFilters
                  ? 'No se encontraron ofertas con los filtros aplicados.'
                  : 'Aún no hay ofertas disponibles. Intenta más tarde.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Responsive grid layout
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
              itemBuilder: (context, index) {
                final offer = offers[index];
                final company = offer.companyId == null
                    ? null
                    : state.companiesById[offer.companyId!];
                return ModernJobOfferCard(
                  title: offer.title,
                  company:
                      offer.companyName ??
                      company?.name ??
                      'Empresa no especificada',
                  avatarUrl: offer.companyAvatarUrl ?? company?.avatarUrl,
                  salary: _formatSalary(offer),
                  location: offer.location,
                  modality: offer.jobType ?? 'Modalidad no especificada',
                  tags: _extractTags(offer),
                  onTap: () => context.push('/job-offer/${offer.id}'),
                );
              },
            ),
          );

          if (!state.isLoadingMore) return grid;
          return Stack(
            children: [
              grid,
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
        },
      );
    }

    // Single column layout for narrow screens
    final list = NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleScroll(context, notification),
      child: ListView.builder(
        itemCount: offers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final offer = offers[index];
          final company = offer.companyId == null
              ? null
              : state.companiesById[offer.companyId!];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ModernJobOfferCard(
              title: offer.title,
              company:
                  offer.companyName ??
                  company?.name ??
                  'Empresa no especificada',
              avatarUrl: offer.companyAvatarUrl ?? company?.avatarUrl,
              salary: _formatSalary(offer),
              location: offer.location,
              modality: offer.jobType ?? 'Modalidad no especificada',
              tags: _extractTags(offer),
              onTap: () => context.push('/job-offer/${offer.id}'),
            ),
          );
        },
      ),
    );
    if (!state.isLoadingMore) return list;
    return Stack(
      children: [
        list,
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

  List<String>? _extractTags(JobOffer offer) {
    final tags = <String>[];

    if (offer.education != null && offer.education!.isNotEmpty) {
      tags.add(offer.education!);
    }

    // Add more tag extraction logic as needed
    if (offer.keyIndicators != null && offer.keyIndicators!.isNotEmpty) {
      final indicators = offer.keyIndicators!.split(',');
      tags.addAll(indicators.take(2).map((e) => e.trim()));
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

String? _formatSalary(JobOffer offer) {
  final min = offer.salaryMin?.trim();
  final max = offer.salaryMax?.trim();

  final hasMin = min != null && min.isNotEmpty;
  final hasMax = max != null && max.isNotEmpty;

  if (hasMin && hasMax) return '$min - $max';
  if (hasMin) return 'Desde $min';
  if (hasMax) return 'Hasta $max';
  return null;
}
