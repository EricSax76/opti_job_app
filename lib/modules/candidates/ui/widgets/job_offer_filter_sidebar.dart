import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/job_offer_filter_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/cubits/job_offer_location_catalog_cubit.dart';
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
    this.onBackgroundTap,
  });

  final JobOfferFilters currentFilters;
  final ValueChanged<JobOfferFilters> onFiltersChanged;
  final VoidCallback? onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => JobOfferFilterCubit(
            initialFilters: currentFilters,
            onFiltersChanged: onFiltersChanged,
          ),
        ),
        BlocProvider(
          create: (context) =>
              JobOfferLocationCatalogCubit()
                ..initialize(initialProvinceId: currentFilters.provinceId),
        ),
      ],
      child: _JobOfferFilterSidebarContent(
        currentFilters: currentFilters,
        onBackgroundTap: onBackgroundTap,
      ),
    );
  }
}

class _JobOfferFilterSidebarContent extends StatelessWidget {
  const _JobOfferFilterSidebarContent({
    required this.currentFilters,
    this.onBackgroundTap,
  });

  final JobOfferFilters currentFilters;
  final VoidCallback? onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = JobOfferFilterPalette.fromTheme(theme);

    return MultiBlocListener(
      listeners: [
        BlocListener<JobOfferFilterCubit, JobOfferFilterState>(
          listenWhen: (previous, current) =>
              previous.filters != current.filters,
          listener: (context, state) {
            if (state.filters == currentFilters) return;
          },
        ),
        BlocListener<JobOfferFilterCubit, JobOfferFilterState>(
          listenWhen: (previous, current) =>
              previous.filters.provinceId != current.filters.provinceId,
          listener: (context, state) {
            context
                .read<JobOfferLocationCatalogCubit>()
                .loadMunicipalitiesForProvince(state.filters.provinceId);
          },
        ),
      ],
      child: _SidebarBody(
        palette: palette,
        isDark: theme.brightness == Brightness.dark,
        currentFilters: currentFilters,
        onBackgroundTap: onBackgroundTap,
      ),
    );
  }
}

class _SidebarBody extends StatefulWidget {
  const _SidebarBody({
    required this.palette,
    required this.isDark,
    required this.currentFilters,
    this.onBackgroundTap,
  });

  final JobOfferFilterPalette palette;
  final bool isDark;
  final JobOfferFilters currentFilters;
  final VoidCallback? onBackgroundTap;

  @override
  State<_SidebarBody> createState() => _SidebarBodyState();
}

class _SidebarBodyState extends State<_SidebarBody> {
  @override
  void didUpdateWidget(covariant _SidebarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilters != oldWidget.currentFilters) {
      context.read<JobOfferFilterCubit>().syncExternalFilters(
        widget.currentFilters,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      JobOfferLocationCatalogCubit,
      JobOfferLocationCatalogState
    >(
      builder: (context, catalogState) {
        return BlocBuilder<JobOfferFilterCubit, JobOfferFilterState>(
          builder: (context, state) {
            final cubit = context.read<JobOfferFilterCubit>();
            final locationCatalogCubit = context
                .read<JobOfferLocationCatalogCubit>();
            final filters = state.filters;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBackgroundTap,
              child: Container(
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
                        inputStyle: const JobOfferFilterInputStyle(
                          borderRadius: JobOfferFilterSidebarTokens
                              .searchFieldBorderRadius,
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
                        locationCatalogCubit: locationCatalogCubit,
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
              ),
            );
          },
        );
      },
    );
  }
}
