class JobOfferFilters {
  const JobOfferFilters({
    this.searchQuery,
    this.location,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.companyName,
  });

  final String? searchQuery;
  final String? location;
  final String? jobType;
  final double? salaryMin;
  final double? salaryMax;
  final String? education;
  final String? companyName;

  bool get hasActiveFilters =>
      searchQuery != null ||
      location != null ||
      jobType != null ||
      salaryMin != null ||
      salaryMax != null ||
      education != null ||
      companyName != null;

  JobOfferFilters copyWith({
    String? searchQuery,
    String? location,
    String? jobType,
    double? salaryMin,
    double? salaryMax,
    String? education,
    String? companyName,
    bool clearSearchQuery = false,
    bool clearLocation = false,
    bool clearJobType = false,
    bool clearSalaryMin = false,
    bool clearSalaryMax = false,
    bool clearEducation = false,
    bool clearCompanyName = false,
  }) {
    return JobOfferFilters(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      location: clearLocation ? null : (location ?? this.location),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      salaryMin: clearSalaryMin ? null : (salaryMin ?? this.salaryMin),
      salaryMax: clearSalaryMax ? null : (salaryMax ?? this.salaryMax),
      education: clearEducation ? null : (education ?? this.education),
      companyName: clearCompanyName ? null : (companyName ?? this.companyName),
    );
  }

  JobOfferFilters clear() {
    return const JobOfferFilters();
  }
}
