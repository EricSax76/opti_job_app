class Application {
  const Application({
    this.id,
    required this.jobOfferId,
    this.jobOfferTitle,
    this.companyUid,
    required this.candidateUid,
    this.candidateProfileId,
    this.candidateName,
    this.candidateEmail,
    this.candidateAvatarUrl,
    this.curriculumId,
    this.coverLetter,
    this.additionalDocuments,
    required this.status,
    this.pipelineStageId,
    this.pipelineStageName,
    this.pipelineHistory,
    this.knockoutResponses,
    this.assignedTo,
    this.matchScore,
    this.aiMatchResult = const {},
    this.humanOverride = const {},
    this.consentRecordId,
    this.blockedAt,
    this.blockedReason,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
  });

  final String? id;
  final String jobOfferId;
  final String? jobOfferTitle;
  final String? companyUid;
  final String candidateUid;
  final int? candidateProfileId;
  final String? candidateName;
  final String? candidateEmail;
  final String? candidateAvatarUrl;
  final String? curriculumId;
  final String? coverLetter;
  final List<String>? additionalDocuments;
  final String status;
  final String? pipelineStageId;
  final String? pipelineStageName;
  final List<dynamic>? pipelineHistory;
  final Map<String, dynamic>? knockoutResponses;
  final String? assignedTo;
  final double? matchScore;
  final Map<String, dynamic> aiMatchResult;
  final Map<String, dynamic> humanOverride;
  final String? consentRecordId;
  final DateTime? blockedAt;
  final String? blockedReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  factory Application.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return Application(
      id: id,
      jobOfferId:
          (json['jobOfferId'] ?? json['job_offer_id'])?.toString() ?? '',
      jobOfferTitle:
          json['jobOfferTitle'] as String? ??
          json['job_offer_title'] as String?,
      companyUid:
          json['companyUid'] as String? ?? json['company_uid'] as String?,
      candidateUid:
          json['candidateId'] as String? ??
          json['candidate_id']?.toString() ??
          json['candidate_uid']?.toString() ??
          '',
      candidateProfileId: parseNullableInt(
        json['candidateProfileId'] ?? json['candidate_profile_id'],
      ),
      candidateName:
          json['candidateName'] as String? ?? json['candidate_name'] as String?,
      candidateEmail:
          json['candidateEmail'] as String? ??
          json['candidate_email'] as String?,
      candidateAvatarUrl: json['candidateAvatarUrl'] as String?,
      curriculumId: json['curriculumId'] as String?,
      coverLetter: json['coverLetter'] as String?,
      additionalDocuments: json['additional_documents'] != null
          ? List<String>.from(json['additional_documents'] as Iterable)
          : null,
      status: json['status'] as String? ?? 'submitted',
      pipelineStageId: json['pipelineStageId'] as String?,
      pipelineStageName: json['pipelineStageName'] as String?,
      pipelineHistory: json['pipelineHistory'] as List<dynamic>?,
      knockoutResponses: json['knockoutResponses'] as Map<String, dynamic>?,
      assignedTo: json['assignedTo'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble(),
      aiMatchResult: json['aiMatchResult'] as Map<String, dynamic>? ?? const {},
      humanOverride: json['humanOverride'] as Map<String, dynamic>? ?? const {},
      consentRecordId: json['consentRecordId'] as String?,
      blockedAt: parseDate(json['blockedAt']),
      blockedReason: json['blockedReason'] as String?,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      submittedAt: parseDate(json['submitted_at'] ?? json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobOfferId': jobOfferId,
      if (jobOfferTitle != null) 'jobOfferTitle': jobOfferTitle,
      if (companyUid != null) 'companyUid': companyUid,
      'candidateId': candidateUid,
      if (candidateProfileId != null) 'candidateProfileId': candidateProfileId,
      if (candidateName != null) 'candidateName': candidateName,
      if (candidateEmail != null) 'candidateEmail': candidateEmail,
      if (candidateAvatarUrl != null) 'candidateAvatarUrl': candidateAvatarUrl,
      if (curriculumId != null) 'curriculumId': curriculumId,
      if (coverLetter != null) 'coverLetter': coverLetter,
      if (additionalDocuments != null)
        'additional_documents': additionalDocuments,
      'status': status,
      if (pipelineStageId != null) 'pipelineStageId': pipelineStageId,
      if (pipelineStageName != null) 'pipelineStageName': pipelineStageName,
      if (pipelineHistory != null) 'pipelineHistory': pipelineHistory,
      if (knockoutResponses != null) 'knockoutResponses': knockoutResponses,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (matchScore != null) 'match_score': matchScore,
      if (aiMatchResult.isNotEmpty) 'aiMatchResult': aiMatchResult,
      if (humanOverride.isNotEmpty) 'humanOverride': humanOverride,
      if (consentRecordId != null) 'consentRecordId': consentRecordId,
      if (blockedAt != null) 'blockedAt': blockedAt!.toIso8601String(),
      if (blockedReason != null) 'blockedReason': blockedReason,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
      if (submittedAt != null) 'submitted_at': submittedAt?.toIso8601String(),
    };
  }

  Application copyWith({
    String? id,
    String? jobOfferId,
    String? jobOfferTitle,
    String? companyUid,
    String? candidateUid,
    int? candidateProfileId,
    String? candidateName,
    String? candidateEmail,
    String? candidateAvatarUrl,
    String? curriculumId,
    String? coverLetter,
    List<String>? additionalDocuments,
    String? status,
    String? pipelineStageId,
    String? pipelineStageName,
    List<dynamic>? pipelineHistory,
    Map<String, dynamic>? knockoutResponses,
    String? assignedTo,
    double? matchScore,
    Map<String, dynamic>? aiMatchResult,
    Map<String, dynamic>? humanOverride,
    String? consentRecordId,
    DateTime? blockedAt,
    String? blockedReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) {
    return Application(
      id: id ?? this.id,
      jobOfferId: jobOfferId ?? this.jobOfferId,
      jobOfferTitle: jobOfferTitle ?? this.jobOfferTitle,
      companyUid: companyUid ?? this.companyUid,
      candidateUid: candidateUid ?? this.candidateUid,
      candidateProfileId: candidateProfileId ?? this.candidateProfileId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      candidateAvatarUrl: candidateAvatarUrl ?? this.candidateAvatarUrl,
      curriculumId: curriculumId ?? this.curriculumId,
      coverLetter: coverLetter ?? this.coverLetter,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
      status: status ?? this.status,
      pipelineStageId: pipelineStageId ?? this.pipelineStageId,
      pipelineStageName: pipelineStageName ?? this.pipelineStageName,
      pipelineHistory: pipelineHistory ?? this.pipelineHistory,
      knockoutResponses: knockoutResponses ?? this.knockoutResponses,
      assignedTo: assignedTo ?? this.assignedTo,
      matchScore: matchScore ?? this.matchScore,
      aiMatchResult: aiMatchResult ?? this.aiMatchResult,
      humanOverride: humanOverride ?? this.humanOverride,
      consentRecordId: consentRecordId ?? this.consentRecordId,
      blockedAt: blockedAt ?? this.blockedAt,
      blockedReason: blockedReason ?? this.blockedReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
