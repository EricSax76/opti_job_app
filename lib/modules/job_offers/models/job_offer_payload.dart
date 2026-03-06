class JobOfferPayload {
  const JobOfferPayload({
    required this.title,
    required this.description,
    required this.location,
    this.provinceId,
    this.provinceName,
    this.municipalityId,
    this.municipalityName,
    required this.companyId,
    required this.companyUid,
    required this.companyName,
    this.companyAvatarUrl,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    this.education,
    this.jobCategory,
    this.workSchedule,
    this.contractType,
    this.jobType,
    this.keyIndicators,
    this.pipelineId,
    this.pipelineStages,
    this.knockoutQuestions,
    this.languageCheckResult,
  });

  final String title;
  final String description;
  final String location;
  final String? provinceId;
  final String? provinceName;
  final String? municipalityId;
  final String? municipalityName;
  final int companyId;
  final String companyUid;
  final String companyName;
  final String? companyAvatarUrl;
  final String salaryMin;
  final String salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final String? education;
  final String? jobCategory;
  final String? workSchedule;
  final String? contractType;
  final String? jobType;
  final String? keyIndicators;
  final String? pipelineId;
  final List<dynamic>? pipelineStages;
  final List<dynamic>? knockoutQuestions;
  final Map<String, dynamic>? languageCheckResult;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'province_id': _normalizeNullableString(provinceId),
      'province_name': _normalizeNullableString(provinceName),
      'municipality_id': _normalizeNullableString(municipalityId),
      'municipality_name': _normalizeNullableString(municipalityName),
      'company_id': companyId,
      'company_uid': companyUid,
      'company_name': companyName,
      'company_avatar_url': companyAvatarUrl,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'salary_period': salaryPeriod,
      'education': education,
      'job_category': jobCategory,
      'work_schedule': workSchedule,
      'contract_type': contractType,
      'job_type': jobType,
      'key_indicators': keyIndicators,
      if (pipelineId != null) 'pipelineId': pipelineId,
      if (pipelineStages != null) 'pipelineStages': pipelineStages,
      if (knockoutQuestions != null) 'knockoutQuestions': knockoutQuestions,
      'language_check_result': languageCheckResult,
    };
  }
}

String? _normalizeNullableString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
