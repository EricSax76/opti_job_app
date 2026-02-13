import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/calendar_panel.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_section.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _showFilters = true;
  bool _isMobileFiltersOpen = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 600;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSidebar && _showFilters)
              BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
                selector: (state) => state.activeFilters,
                builder: (context, filters) {
                  return JobOfferFilterSidebar(
                    currentFilters: filters,
                    onFiltersChanged: context
                        .read<JobOffersCubit>()
                        .applyFilters,
                  );
                },
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primaryContainer.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(uiCardRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $candidateName',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aquí tienes las mejores ofertas seleccionadas para ti.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filter Toggle & Title
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _handleFiltersToggle(
                            context: context,
                            showSidebar: showSidebar,
                          ),
                          icon: Icon(
                            showSidebar
                                ? (_showFilters
                                      ? Icons.filter_list_off
                                      : Icons.filter_list)
                                : (_isMobileFiltersOpen
                                      ? Icons.filter_list_off
                                      : Icons.filter_list),
                          ),
                          label: Text(
                            showSidebar
                                ? (_showFilters ? 'Ocultar filtros' : 'Filtros')
                                : (_isMobileFiltersOpen
                                      ? 'Cerrar filtros'
                                      : 'Filtros'),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                          ),
                        ),
                        const Spacer(),
                        // Add other actions if needed
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: DashboardOffersSection(
                              showTwoColumns: showSidebar,
                            ),
                          ),
                          const SizedBox(height: 24),
                          BlocBuilder<CalendarCubit, CalendarState>(
                            builder: (context, state) {
                              return CalendarPanel(state: state);
                            },
                          ),
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

  Future<void> _handleFiltersToggle({
    required BuildContext context,
    required bool showSidebar,
  }) async {
    if (showSidebar) {
      setState(() => _showFilters = !_showFilters);
      return;
    }

    if (_isMobileFiltersOpen) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _isMobileFiltersOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
            selector: (state) => state.activeFilters,
            builder: (context, filters) {
              return JobOfferFilterSidebar(
                currentFilters: filters,
                onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
              );
            },
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _isMobileFiltersOpen = false);
  }
}
