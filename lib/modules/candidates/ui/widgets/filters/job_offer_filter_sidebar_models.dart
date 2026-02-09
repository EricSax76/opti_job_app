import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterPalette {
  const JobOfferFilterPalette({
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.surface,
    required this.inputFill,
  });

  final Color ink;
  final Color muted;
  final Color border;
  final Color accent;
  final Color surface;
  final Color inputFill;

  factory JobOfferFilterPalette.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return JobOfferFilterPalette(
      ink: isDark ? uiDarkInk : uiInk,
      muted: isDark ? uiDarkMuted : uiMuted,
      border: isDark ? uiDarkBorder : uiBorder,
      accent: uiAccent,
      surface: isDark ? uiDarkSurface : Colors.white,
      inputFill: isDark ? uiDarkBackground : Colors.white,
    );
  }
}

class JobOfferFilterSidebarViewState {
  const JobOfferFilterSidebarViewState({
    required this.filters,
    required this.minSalary,
    required this.maxSalary,
  });

  final JobOfferFilters filters;
  final double minSalary;
  final double maxSalary;

  bool get hasActiveFilters => filters.hasActiveFilters;

  factory JobOfferFilterSidebarViewState.fromFilters(
    JobOfferFilters filters, {
    double defaultMin = JobOfferFilterSidebarTokens.minSalary,
    double defaultMax = JobOfferFilterSidebarTokens.maxSalary,
  }) {
    return JobOfferFilterSidebarViewState(
      filters: filters,
      minSalary: filters.salaryMin ?? defaultMin,
      maxSalary: filters.salaryMax ?? defaultMax,
    );
  }

  JobOfferFilterSidebarViewState copyWith({
    JobOfferFilters? filters,
    double? minSalary,
    double? maxSalary,
  }) {
    return JobOfferFilterSidebarViewState(
      filters: filters ?? this.filters,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
    );
  }
}
