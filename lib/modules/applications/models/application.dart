
class Application {
  const Application({
    this.id,
    required this.jobOfferId,
    this.jobOfferTitle,
    this.companyUid,
    required this.candidateUid,
    this.candidateName,
    this.candidateEmail,
    this.candidateProfileId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String jobOfferId;
  final String? jobOfferTitle;
  final String? companyUid;
  final String candidateUid;
  final String? candidateName;
  final String? candidateEmail;
  final int? candidateProfileId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      jobOfferId: (json['jobOfferId'] ?? json['job_offer_id'])?.toString() ?? '',
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
      candidateName:
          json['candidateName'] as String? ?? json['candidate_name'] as String?,
      candidateEmail:
          json['candidateEmail'] as String? ??
          json['candidate_email'] as String?,
      candidateProfileId: parseNullableInt(
        json['candidate_profile_id'] ?? json['candidateProfileId'],
      ),
      status: json['status'] as String? ?? 'pending',
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobOfferId': jobOfferId,
      if (jobOfferTitle != null) 'jobOfferTitle': jobOfferTitle,
      if (companyUid != null) 'companyUid': companyUid,
      'candidateId': candidateUid,
      if (candidateName != null) 'candidateName': candidateName,
      if (candidateEmail != null) 'candidateEmail': candidateEmail,
      if (candidateProfileId != null) 'candidateProfileId': candidateProfileId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Application copyWith({
    String? id,
    String? jobOfferId,
    String? jobOfferTitle,
    String? companyUid,
    String? candidateUid,
    String? candidateName,
    String? candidateEmail,
    int? candidateProfileId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      jobOfferId: jobOfferId ?? this.jobOfferId,
      jobOfferTitle: jobOfferTitle ?? this.jobOfferTitle,
      companyUid: companyUid ?? this.companyUid,
      candidateUid: candidateUid ?? this.candidateUid,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      candidateProfileId: candidateProfileId ?? this.candidateProfileId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
