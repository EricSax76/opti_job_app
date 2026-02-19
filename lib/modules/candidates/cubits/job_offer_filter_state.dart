part of 'job_offer_filter_cubit.dart';

class JobOfferFilterState extends Equatable {
  const JobOfferFilterState({
    required this.filters,
    required this.minSalary,
    required this.maxSalary,
  });

  factory JobOfferFilterState.initial(JobOfferFilters filters) {
    return JobOfferFilterState(
      filters: filters,
      minSalary: JobOfferFilterSidebarTokens.minSalary,
      maxSalary: JobOfferFilterSidebarTokens.maxSalary,
    );
  }

  final JobOfferFilters filters;
  final double minSalary;
  final double maxSalary;

  bool get hasActiveFilters => filters.hasActiveFilters;

  JobOfferFilterState copyWith({
    JobOfferFilters? filters,
    double? minSalary,
    double? maxSalary,
  }) {
    return JobOfferFilterState(
      filters: filters ?? this.filters,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
    );
  }

  @override
  List<Object?> get props => [filters, minSalary, maxSalary];
}
