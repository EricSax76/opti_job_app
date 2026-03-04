import 'package:opti_job_app/modules/skills/models/skill.dart';

class JobOffer {
  const JobOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.status,
    this.provinceId,
    this.provinceName,
    this.municipalityId,
    this.municipalityName,
    this.companyId,
    this.companyUid,
    this.companyName,
    this.companyAvatarUrl,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.salaryPeriod,
    this.education,
    this.jobCategory,
    this.workSchedule,
    this.contractType,
    this.keyIndicators,
    this.pipelineId,
    this.pipelineStages,
    this.knockoutQuestions,
    this.languageCheckResult,
    this.salaryGapJustificationRequired = false,
    this.salaryGapAudit,
    this.publicationBlockReason,
    this.multiposting,
    this.multipostingEnabledChannels = const [],
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String? status;
  final String? provinceId;
  final String? provinceName;
  final String? municipalityId;
  final String? municipalityName;
  final int? companyId;
  final String? companyUid;
  final String? companyName;
  final String? companyAvatarUrl;
  final String? jobType;
  final String? salaryMin;
  final String? salaryMax;
  final String? salaryCurrency;
  final String? salaryPeriod;
  final String? education;
  final String? jobCategory;
  final String? workSchedule;
  final String? contractType;
  final String? keyIndicators;
  final String? pipelineId;
  final List<dynamic>? pipelineStages;
  final List<dynamic>? knockoutQuestions;
  final Map<String, dynamic>? languageCheckResult;
  final bool salaryGapJustificationRequired;
  final Map<String, dynamic>? salaryGapAudit;
  final String? publicationBlockReason;
  final Map<String, dynamic>? multiposting;
  final List<String> multipostingEnabledChannels;
  final List<JobOfferSkill> requiredSkills;
  final List<Skill> preferredSkills;
  final DateTime? createdAt;

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: _readNullableString(json['status']),
      provinceId: _readNullableString(
        json['province_id'] ?? json['provinceId'],
      ),
      provinceName: _readNullableString(
        json['province_name'] ?? json['provinceName'],
      ),
      municipalityId: _readNullableString(
        json['municipality_id'] ?? json['municipalityId'],
      ),
      municipalityName: _readNullableString(
        json['municipality_name'] ?? json['municipalityName'],
      ),
      companyId: _tryParseInt(
        json['company_id'] ?? json['companyId'] ?? json['owner_id'],
      ),
      companyUid:
          json['company_uid'] as String? ??
          json['companyUid'] as String? ??
          json['owner_uid'] as String?,
      companyName:
          json['company_name'] as String? ?? json['companyName'] as String?,
      companyAvatarUrl:
          json['company_avatar_url'] as String? ??
          json['companyAvatarUrl'] as String?,
      jobType: json['job_type'] as String? ?? json['jobType'] as String?,
      salaryMin: json['salary_min'] as String? ?? json['salaryMin'] as String?,
      salaryMax: json['salary_max'] as String? ?? json['salaryMax'] as String?,
      salaryCurrency: json['salary_currency'] as String? ?? json['salaryCurrency'] as String?,
      salaryPeriod: json['salary_period'] as String? ?? json['salaryPeriod'] as String?,
      education: json['education'] as String?,
      jobCategory:
          json['job_category'] as String? ?? json['jobCategory'] as String?,
      workSchedule:
          json['work_schedule'] as String? ?? json['workSchedule'] as String?,
      contractType: json['contract_type'] as String?,
      keyIndicators: json['key_indicators'] as String?,
      pipelineId: json['pipelineId'] as String?,
      pipelineStages: json['pipelineStages'] as List<dynamic>?,
      knockoutQuestions: json['knockoutQuestions'] as List<dynamic>?,
      languageCheckResult: json['languageCheckResult'] as Map<String, dynamic>?,
      salaryGapJustificationRequired:
          json['salary_gap_justification_required'] as bool? ??
          json['salaryGapJustificationRequired'] as bool? ??
          false,
      salaryGapAudit:
          json['salary_gap_audit'] as Map<String, dynamic>? ??
          json['salaryGapAudit'] as Map<String, dynamic>?,
      publicationBlockReason:
          json['publication_block_reason'] as String? ??
          json['publicationBlockReason'] as String?,
      multiposting:
          json['multiposting'] as Map<String, dynamic>?,
      multipostingEnabledChannels:
          (json['multiposting_enabled_channels'] as List<dynamic>? ??
                  json['multipostingEnabledChannels'] as List<dynamic>? ??
                  const [])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      requiredSkills: (json['requiredSkills'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(JobOfferSkill.fromJson)
          .toList(),
      preferredSkills: (json['preferredSkills'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Skill.fromJson)
          .toList(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      if (status != null) 'status': status,
      'province_id': provinceId,
      'province_name': provinceName,
      'municipality_id': municipalityId,
      'municipality_name': municipalityName,
      'company_id': companyId,
      'company_uid': companyUid,
      'company_name': companyName,
      'company_avatar_url': companyAvatarUrl,
      'job_type': jobType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'salary_period': salaryPeriod,
      'education': education,
      'job_category': jobCategory,
      'work_schedule': workSchedule,
      if (contractType != null) 'contract_type': contractType,
      if (keyIndicators != null) 'key_indicators': keyIndicators,
      if (pipelineId != null) 'pipelineId': pipelineId,
      if (pipelineStages != null) 'pipelineStages': pipelineStages,
      if (knockoutQuestions != null) 'knockoutQuestions': knockoutQuestions,
      if (languageCheckResult != null)
        'languageCheckResult': languageCheckResult,
      'salary_gap_justification_required': salaryGapJustificationRequired,
      if (salaryGapAudit != null) 'salary_gap_audit': salaryGapAudit,
      if (publicationBlockReason != null)
        'publication_block_reason': publicationBlockReason,
      if (multiposting != null) 'multiposting': multiposting,
      'multiposting_enabled_channels': multipostingEnabledChannels,
      'requiredSkills': requiredSkills.map((s) => s.toJson()).toList(),
      'preferredSkills': preferredSkills.map((s) => s.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  JobOffer copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? status,
    String? provinceId,
    String? provinceName,
    String? municipalityId,
    String? municipalityName,
    int? companyId,
    String? companyUid,
    String? companyName,
    String? companyAvatarUrl,
    String? jobType,
    String? salaryMin,
    String? salaryMax,
    String? salaryCurrency,
    String? salaryPeriod,
    String? education,
    String? jobCategory,
    String? workSchedule,
    String? contractType,
    String? keyIndicators,
    String? pipelineId,
    List<dynamic>? pipelineStages,
    List<dynamic>? knockoutQuestions,
    Map<String, dynamic>? languageCheckResult,
    bool? salaryGapJustificationRequired,
    Map<String, dynamic>? salaryGapAudit,
    String? publicationBlockReason,
    Map<String, dynamic>? multiposting,
    List<String>? multipostingEnabledChannels,
    List<JobOfferSkill>? requiredSkills,
    List<Skill>? preferredSkills,
    DateTime? createdAt,
  }) {
    return JobOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      provinceId: provinceId ?? this.provinceId,
      provinceName: provinceName ?? this.provinceName,
      municipalityId: municipalityId ?? this.municipalityId,
      municipalityName: municipalityName ?? this.municipalityName,
      companyId: companyId ?? this.companyId,
      companyUid: companyUid ?? this.companyUid,
      companyName: companyName ?? this.companyName,
      companyAvatarUrl: companyAvatarUrl ?? this.companyAvatarUrl,
      jobType: jobType ?? this.jobType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      education: education ?? this.education,
      jobCategory: jobCategory ?? this.jobCategory,
      workSchedule: workSchedule ?? this.workSchedule,
      contractType: contractType ?? this.contractType,
      keyIndicators: keyIndicators ?? this.keyIndicators,
      pipelineId: pipelineId ?? this.pipelineId,
      pipelineStages: pipelineStages ?? this.pipelineStages,
      knockoutQuestions: knockoutQuestions ?? this.knockoutQuestions,
      languageCheckResult: languageCheckResult ?? this.languageCheckResult,
      salaryGapJustificationRequired: salaryGapJustificationRequired ??
          this.salaryGapJustificationRequired,
      salaryGapAudit: salaryGapAudit ?? this.salaryGapAudit,
      publicationBlockReason: publicationBlockReason ?? this.publicationBlockReason,
      multiposting: multiposting ?? this.multiposting,
      multipostingEnabledChannels:
          multipostingEnabledChannels ?? this.multipostingEnabledChannels,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _tryParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

String? _readNullableString(dynamic value) {
  if (value == null) return null;
  final parsed = value.toString().trim();
  if (parsed.isEmpty) return null;
  return parsed;
}

class JobOfferSkill {
  const JobOfferSkill({
    required this.skillId,
    required this.name,
    required this.minimumLevel,
  });

  final String skillId;
  final String name;
  final SkillLevel minimumLevel;

  factory JobOfferSkill.fromJson(Map<String, dynamic> json) {
    return JobOfferSkill(
      skillId: json['skillId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      minimumLevel: SkillLevel.fromString(json['minimumLevel'] as String? ?? 'beginner'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'name': name,
      'minimumLevel': minimumLevel.name,
    };
  }
}
