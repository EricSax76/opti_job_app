import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/cubits/job_offer_filter_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/models/job_offer_filter_options.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_field_decorators.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_field_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_shell_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final palette = JobOfferFilterPalette.fromTheme(theme);

    return BlocListener<JobOfferFilterCubit, JobOfferFilterState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) {
        // Parent owns source of truth. Cubit synchronization is handled in didUpdateWidget.
        if (state.filters == currentFilters) return;
      },
      child: _SidebarBody(
        palette: palette,
        isDark: isDark,
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
                    hintFontSize: JobOfferFilterSidebarTokens.searchFontSize,
                    borderRadius:
                        JobOfferFilterSidebarTokens.searchFieldBorderRadius,
                    contentPadding:
                        JobOfferFilterSidebarTokens.searchFieldContentPadding,
                  ),
                  onClear: cubit.clearSearchQuery,
                  onChanged: cubit.updateSearchQuery,
                ),
                const SizedBox(
                  height:
                      JobOfferFilterSidebarTokens.searchToNextSectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Ubicación',
                  icon: Icons.location_on_outlined,
                  palette: widget.palette,
                  child: JobOfferFilterTextField(
                    palette: widget.palette,
                    hintText: 'Ej: Madrid, Barcelona',
                    controller: cubit.locationController,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: (val) => cubit.updateLocation(val),
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Modalidad',
                  icon: Icons.work_outline,
                  palette: widget.palette,
                  child: JobOfferFilterDropdownField(
                    palette: widget.palette,
                    fieldKey: ValueKey(filters.jobType),
                    initialValue: filters.jobType,
                    items: jobOfferFilterJobTypes,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: cubit.updateJobType,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Rango Salarial',
                  icon: Icons.payments_outlined,
                  palette: widget.palette,
                  child: JobOfferSalaryRangeFilter(
                    palette: widget.palette,
                    minSalary: state.minSalary,
                    maxSalary: state.maxSalary,
                    onChanged: cubit.updateSalaryPreview,
                    onChangeEnd: cubit.commitSalaryRange,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Educación',
                  icon: Icons.school_outlined,
                  palette: widget.palette,
                  child: JobOfferFilterDropdownField(
                    palette: widget.palette,
                    fieldKey: ValueKey(filters.education),
                    initialValue: filters.education,
                    items: jobOfferFilterEducationLevels,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: cubit.updateEducation,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Empresa',
                  icon: Icons.business_outlined,
                  palette: widget.palette,
                  child: JobOfferFilterTextField(
                    palette: widget.palette,
                    hintText: 'Nombre de la empresa',
                    controller: cubit.companyController,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: (val) => cubit.updateCompany(val),
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.clearButtonTopSpacing,
                ),
                if (state.hasActiveFilters)
                  JobOfferClearFiltersButton(
                    palette: widget.palette,
                    onPressed: cubit.clearAllFilters,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
