class AiJobOfferDraft {
  const AiJobOfferDraft({
    required this.title,
    required this.description,
    required this.location,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.keyIndicators,
  });

  final String title;
  final String description;
  final String location;
  final String? jobType;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? keyIndicators;

  factory AiJobOfferDraft.fromJson(Map<String, dynamic> json) {
    String? s(dynamic value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final title = s(json['title']) ?? '';
    final description = s(json['description']) ?? '';
    final location = s(json['location']) ?? '';
    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      throw const FormatException('Missing required fields');
    }

    return AiJobOfferDraft(
      title: title,
      description: description,
      location: location,
      jobType: s(json['job_type'] ?? json['jobType']),
      salaryMin: s(json['salary_min'] ?? json['salaryMin']),
      salaryMax: s(json['salary_max'] ?? json['salaryMax']),
      education: s(json['education']),
      keyIndicators: s(json['key_indicators'] ?? json['keyIndicators']),
    );
  }
}

