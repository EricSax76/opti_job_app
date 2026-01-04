import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class JobOffer {
  const JobOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.companyId,
    this.companyUid,
    this.companyName,
    this.companyAvatarUrl,
    this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.keyIndicators,
    this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String location;
  final int? companyId;
  final String? companyUid;
  final String? companyName;
  final String? companyAvatarUrl;
  final String? jobType;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? keyIndicators;
  final DateTime? createdAt;

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      companyId: _tryParseInt(
        json['company_id'] ?? json['companyId'] ?? json['owner_id'],
      ),
      companyUid: json['company_uid'] as String? ??
          json['companyUid'] as String? ??
          json['owner_uid'] as String?,
      companyName:
          json['company_name'] as String? ?? json['companyName'] as String?,
      companyAvatarUrl: json['company_avatar_url'] as String? ??
          json['companyAvatarUrl'] as String?,
      jobType: json['job_type'] as String? ?? json['jobType'] as String?,
      salaryMin: json['salary_min'] as String? ?? json['salaryMin'] as String?,
      salaryMax: json['salary_max'] as String? ?? json['salaryMax'] as String?,
      education: json['education'] as String?,
      keyIndicators:
          json['key_indicators'] as String? ?? json['keyIndicators'] as String?,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'company_id': companyId,
      'company_uid': companyUid,
      'company_name': companyName,
      'company_avatar_url': companyAvatarUrl,
      'job_type': jobType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'key_indicators': keyIndicators,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  JobOffer copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    int? companyId,
    String? companyUid,
    String? companyName,
    String? companyAvatarUrl,
    String? jobType,
    String? salaryMin,
    String? salaryMax,
    String? education,
    String? keyIndicators,
    DateTime? createdAt,
  }) {
    return JobOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      companyId: companyId ?? this.companyId,
      companyUid: companyUid ?? this.companyUid,
      companyName: companyName ?? this.companyName,
      companyAvatarUrl: companyAvatarUrl ?? this.companyAvatarUrl,
      jobType: jobType ?? this.jobType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      education: education ?? this.education,
      keyIndicators: keyIndicators ?? this.keyIndicators,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
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
