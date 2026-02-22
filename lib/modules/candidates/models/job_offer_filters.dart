import 'package:equatable/equatable.dart';

class JobOfferFilters extends Equatable {
  const JobOfferFilters({
    this.searchQuery,
    this.location,
    this.provinceId,
    this.provinceName,
    this.municipalityId,
    this.municipalityName,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.jobCategory,
    this.workSchedule,
    this.contractType,
    this.datePosted,
    this.companyName,
  });

  final String? searchQuery;
  final String? location;
  final String? provinceId;
  final String? provinceName;
  final String? municipalityId;
  final String? municipalityName;
  final String? jobType;
  final double? salaryMin;
  final double? salaryMax;
  final String? education;
  final String? jobCategory;
  final String? workSchedule;
  final String? contractType;
  final String? datePosted;
  final String? companyName;

  bool get hasActiveFilters =>
      searchQuery != null ||
      location != null ||
      provinceId != null ||
      municipalityId != null ||
      jobType != null ||
      salaryMin != null ||
      salaryMax != null ||
      education != null ||
      jobCategory != null ||
      workSchedule != null ||
      contractType != null ||
      datePosted != null ||
      companyName != null;

  JobOfferFilters copyWith({
    String? searchQuery,
    String? location,
    String? provinceId,
    String? provinceName,
    String? municipalityId,
    String? municipalityName,
    String? jobType,
    double? salaryMin,
    double? salaryMax,
    String? education,
    String? jobCategory,
    String? workSchedule,
    String? contractType,
    String? datePosted,
    String? companyName,
    bool clearSearchQuery = false,
    bool clearLocation = false,
    bool clearProvinceId = false,
    bool clearProvinceName = false,
    bool clearMunicipalityId = false,
    bool clearMunicipalityName = false,
    bool clearJobType = false,
    bool clearSalaryMin = false,
    bool clearSalaryMax = false,
    bool clearEducation = false,
    bool clearJobCategory = false,
    bool clearWorkSchedule = false,
    bool clearContractType = false,
    bool clearDatePosted = false,
    bool clearCompanyName = false,
  }) {
    return JobOfferFilters(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      location: clearLocation ? null : (location ?? this.location),
      provinceId: clearProvinceId ? null : (provinceId ?? this.provinceId),
      provinceName: clearProvinceName
          ? null
          : (provinceName ?? this.provinceName),
      municipalityId: clearMunicipalityId
          ? null
          : (municipalityId ?? this.municipalityId),
      municipalityName: clearMunicipalityName
          ? null
          : (municipalityName ?? this.municipalityName),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      salaryMin: clearSalaryMin ? null : (salaryMin ?? this.salaryMin),
      salaryMax: clearSalaryMax ? null : (salaryMax ?? this.salaryMax),
      education: clearEducation ? null : (education ?? this.education),
      jobCategory:
          clearJobCategory ? null : (jobCategory ?? this.jobCategory),
      workSchedule:
          clearWorkSchedule ? null : (workSchedule ?? this.workSchedule),
      contractType:
          clearContractType ? null : (contractType ?? this.contractType),
      datePosted: clearDatePosted ? null : (datePosted ?? this.datePosted),
      companyName: clearCompanyName ? null : (companyName ?? this.companyName),
    );
  }

  JobOfferFilters clear() {
    return const JobOfferFilters();
  }

  @override
  List<Object?> get props => [
    searchQuery,
    location,
    provinceId,
    provinceName,
    municipalityId,
    municipalityName,
    jobType,
    salaryMin,
    salaryMax,
    education,
    jobCategory,
    workSchedule,
    contractType,
    datePosted,
    companyName,
  ];
}
