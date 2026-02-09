import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_options.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_components.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_logic.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterSidebar extends StatefulWidget {
  const JobOfferFilterSidebar({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  final JobOfferFilters currentFilters;
  final ValueChanged<JobOfferFilters> onFiltersChanged;

  @override
  State<JobOfferFilterSidebar> createState() => _JobOfferFilterSidebarState();
}

class _JobOfferFilterSidebarState extends State<JobOfferFilterSidebar> {
  late final JobOfferFilterSidebarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JobOfferFilterSidebarController(
      initialFilters: widget.currentFilters,
      onFiltersChanged: widget.onFiltersChanged,
    );
  }

  @override
  void didUpdateWidget(JobOfferFilterSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onFiltersChanged != oldWidget.onFiltersChanged) {
      _controller.updateOnFiltersChanged(widget.onFiltersChanged);
    }
    if (widget.currentFilters != oldWidget.currentFilters) {
      _controller.syncExternalFilters(widget.currentFilters);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = JobOfferFilterPalette.fromTheme(theme);

    return ValueListenableBuilder<JobOfferFilterSidebarViewState>(
      valueListenable: _controller.state,
      builder: (context, viewState, _) {
        final filters = viewState.filters;
        return Container(
          width: JobOfferFilterSidebarTokens.sidebarWidth,
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: isDark ? 1.0 : 0.8),
            border: Border(right: BorderSide(color: palette.border, width: 1)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              JobOfferFilterSidebarTokens.panelPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JobOfferFilterSidebarHeader(palette: palette),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.panelPadding,
                ),
                JobOfferFilterTextField(
                  palette: palette,
                  hintText: 'Buscar ofertas...',
                  controller: _controller.searchController,
                  prefixIcon: Icons.search,
                  textFontSize: JobOfferFilterSidebarTokens.searchFontSize,
                  inputStyle: const JobOfferFilterInputStyle(
                    hintFontSize: JobOfferFilterSidebarTokens.searchFontSize,
                    borderRadius:
                        JobOfferFilterSidebarTokens.searchFieldBorderRadius,
                    contentPadding:
                        JobOfferFilterSidebarTokens.searchFieldContentPadding,
                  ),
                  onClear: _controller.clearSearchQuery,
                  onChanged: _controller.updateSearchQuery,
                ),
                const SizedBox(
                  height:
                      JobOfferFilterSidebarTokens.searchToNextSectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Ubicación',
                  icon: Icons.location_on_outlined,
                  palette: palette,
                  child: JobOfferFilterTextField(
                    palette: palette,
                    hintText: 'Ej: Madrid, Barcelona',
                    controller: _controller.locationController,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: _controller.updateLocation,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Modalidad',
                  icon: Icons.work_outline,
                  palette: palette,
                  child: JobOfferFilterDropdownField(
                    palette: palette,
                    fieldKey: ValueKey(filters.jobType),
                    initialValue: filters.jobType,
                    items: jobOfferFilterJobTypes,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: _controller.updateJobType,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Rango Salarial',
                  icon: Icons.payments_outlined,
                  palette: palette,
                  child: JobOfferSalaryRangeFilter(
                    palette: palette,
                    minSalary: viewState.minSalary,
                    maxSalary: viewState.maxSalary,
                    onChanged: _controller.updateSalaryPreview,
                    onChangeEnd: _controller.commitSalaryRange,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Educación',
                  icon: Icons.school_outlined,
                  palette: palette,
                  child: JobOfferFilterDropdownField(
                    palette: palette,
                    fieldKey: ValueKey(filters.education),
                    initialValue: filters.education,
                    items: jobOfferFilterEducationLevels,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: _controller.updateEducation,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.sectionSpacing,
                ),
                JobOfferFilterSection(
                  title: 'Empresa',
                  icon: Icons.business_outlined,
                  palette: palette,
                  child: JobOfferFilterTextField(
                    palette: palette,
                    hintText: 'Nombre de la empresa',
                    controller: _controller.companyController,
                    inputStyle: const JobOfferFilterInputStyle(),
                    onChanged: _controller.updateCompany,
                  ),
                ),
                const SizedBox(
                  height: JobOfferFilterSidebarTokens.clearButtonTopSpacing,
                ),
                if (viewState.hasActiveFilters)
                  JobOfferClearFiltersButton(
                    palette: palette,
                    onPressed: _controller.clearAllFilters,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
