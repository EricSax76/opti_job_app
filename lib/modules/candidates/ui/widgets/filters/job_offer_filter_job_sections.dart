import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/candidates/cubits/job_offer_filter_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/models/job_offer_filter_options.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_field_decorators.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_field_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_shell_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterJobSections extends StatelessWidget {
  const JobOfferFilterJobSections({
    super.key,
    required this.palette,
    required this.state,
    required this.cubit,
  });

  final JobOfferFilterPalette palette;
  final JobOfferFilterState state;
  final JobOfferFilterCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobOfferFilterSection(
          title: 'Fecha de publicación',
          icon: Icons.calendar_today_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(filters.datePosted),
            initialValue: filters.datePosted,
            items: jobOfferFilterDatePostedOptions,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateDatePosted,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
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
            onChanged: cubit.updateJobType,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Categoría del puesto',
          icon: Icons.category_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(filters.jobCategory),
            initialValue: filters.jobCategory,
            items: jobOfferFilterJobCategories,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateJobCategory,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Estudios mínimos',
          icon: Icons.school_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(filters.education),
            initialValue: filters.education,
            items: jobOfferFilterEducationLevels,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateEducation,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Jornada laboral',
          icon: Icons.schedule_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(filters.workSchedule),
            initialValue: filters.workSchedule,
            items: jobOfferFilterWorkSchedules,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateWorkSchedule,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Tipo de contrato',
          icon: Icons.description_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(filters.contractType),
            initialValue: filters.contractType,
            items: jobOfferFilterContractTypes,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateContractType,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Rango Salarial',
          icon: Icons.payments_outlined,
          palette: palette,
          child: JobOfferSalaryRangeFilter(
            palette: palette,
            minSalary: state.minSalary,
            maxSalary: state.maxSalary,
            onChanged: cubit.updateSalaryPreview,
            onChangeEnd: cubit.commitSalaryRange,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Empresa',
          icon: Icons.business_outlined,
          palette: palette,
          child: JobOfferFilterTextField(
            palette: palette,
            hintText: 'Nombre de la empresa',
            controller: cubit.companyController,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateCompany,
          ),
        ),
        const SizedBox(
          height: JobOfferFilterSidebarTokens.clearButtonTopSpacing,
        ),
        if (state.hasActiveFilters)
          JobOfferClearFiltersButton(
            palette: palette,
            onPressed: cubit.clearAllFilters,
          ),
      ],
    );
  }
}
