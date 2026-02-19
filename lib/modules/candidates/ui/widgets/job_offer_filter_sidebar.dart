import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/job_offer_filter_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/controllers/job_offer_location_catalog_controller.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_field_decorators.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_job_sections.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_location_sections.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_field_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_shell_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterSidebar extends StatelessWidget {
  const JobOfferFilterSidebar({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  final JobOfferFilters currentFilters;
  final ValueChanged<JobOfferFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JobOfferFilterCubit(
        initialFilters: currentFilters,
        onFiltersChanged: onFiltersChanged,
      ),
      child: _JobOfferFilterSidebarContent(currentFilters: currentFilters),
    );
  }
}

class _JobOfferFilterSidebarContent extends StatelessWidget {
  const _JobOfferFilterSidebarContent({required this.currentFilters});

  final JobOfferFilters currentFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = JobOfferFilterPalette.fromTheme(theme);

    return BlocListener<JobOfferFilterCubit, JobOfferFilterState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) {
        if (state.filters == currentFilters) return;
      },
      child: _SidebarBody(
        palette: palette,
        isDark: theme.brightness == Brightness.dark,
        currentFilters: currentFilters,
      ),
    );
  }
}

class _SidebarBody extends StatefulWidget {
  const _SidebarBody({
    required this.palette,
    required this.isDark,
    required this.currentFilters,
  });

  final JobOfferFilterPalette palette;
  final bool isDark;
  final JobOfferFilters currentFilters;

  @override
  State<_SidebarBody> createState() => _SidebarBodyState();
}

class _SidebarBodyState extends State<_SidebarBody> {
  late final JobOfferLocationCatalogController _locationCatalogController;

  @override
  void initState() {
    super.initState();
    _locationCatalogController = JobOfferLocationCatalogController();
    unawaited(
      _locationCatalogController.initialize(
        initialProvinceId: widget.currentFilters.provinceId,
      ),
    );
  }

  @override
  void dispose() {
    _locationCatalogController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SidebarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilters != oldWidget.currentFilters) {
      context.read<JobOfferFilterCubit>().syncExternalFilters(
        widget.currentFilters,
      );
    }

    if (widget.currentFilters.provinceId !=
        oldWidget.currentFilters.provinceId) {
      unawaited(
        _locationCatalogController.loadMunicipalitiesForProvince(
          widget.currentFilters.provinceId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _locationCatalogController,
      builder: (context, _) {
        final catalogState = _locationCatalogController.state;

        return BlocBuilder<JobOfferFilterCubit, JobOfferFilterState>(
          builder: (context, state) {
            final cubit = context.read<JobOfferFilterCubit>();
            final filters = state.filters;

            return Container(
              width: JobOfferFilterSidebarTokens.sidebarWidth,
              decoration: BoxDecoration(
                color: widget.palette.surface.withValues(
                  alpha: widget.isDark ? 1.0 : 0.8,
                ),
                border: Border(
                  right: BorderSide(
                    color: widget.palette.border,
                    width: uiSpacing4 / 4,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  JobOfferFilterSidebarTokens.panelPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobOfferFilterSidebarHeader(palette: widget.palette),
                    const SizedBox(
                      height: JobOfferFilterSidebarTokens.panelPadding,
                    ),
                    JobOfferFilterTextField(
                      palette: widget.palette,
                      hintText: 'Buscar ofertas...',
                      controller: cubit.searchController,
                      prefixIcon: Icons.search,
                      textFontSize: JobOfferFilterSidebarTokens.searchFontSize,
                      inputStyle: const JobOfferFilterInputStyle(
                        hintFontSize:
                            JobOfferFilterSidebarTokens.searchFontSize,
                        borderRadius:
                            JobOfferFilterSidebarTokens.searchFieldBorderRadius,
                        contentPadding: JobOfferFilterSidebarTokens
                            .searchFieldContentPadding,
                      ),
                      onClear: cubit.clearSearchQuery,
                      onChanged: cubit.updateSearchQuery,
                    ),
                    const SizedBox(
                      height: JobOfferFilterSidebarTokens
                          .searchToNextSectionSpacing,
                    ),
                    JobOfferFilterLocationSections(
                      palette: widget.palette,
                      filters: filters,
                      cubit: cubit,
                      catalogState: catalogState,
                      locationCatalogController: _locationCatalogController,
                    ),
                    const SizedBox(
                      height: JobOfferFilterSidebarTokens.sectionSpacing,
                    ),
                    JobOfferFilterJobSections(
                      palette: widget.palette,
                      state: state,
                      cubit: cubit,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
