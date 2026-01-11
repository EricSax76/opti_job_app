import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Curriculum {
  const Curriculum({
    required this.headline,
    required this.summary,
    required this.phone,
    required this.location,
    required this.skills,
    required this.experiences,
    required this.education,
    this.attachment,
    this.updatedAt,
  });

  final String headline;
  final String summary;
  final String phone;
  final String location;
  final List<String> skills;
  final List<CurriculumItem> experiences;
  final List<CurriculumItem> education;
  final CurriculumAttachment? attachment;
  final DateTime? updatedAt;

  factory Curriculum.empty() {
    return const Curriculum(
      headline: '',
      summary: '',
      phone: '',
      location: '',
      skills: [],
      experiences: [],
      education: [],
    );
  }

  Curriculum copyWith({
    String? headline,
    String? summary,
    String? phone,
    String? location,
    List<String>? skills,
    List<CurriculumItem>? experiences,
    List<CurriculumItem>? education,
    CurriculumAttachment? attachment,
    DateTime? updatedAt,
  }) {
    return Curriculum(
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      attachment: attachment ?? this.attachment,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    return Curriculum(
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      experiences: (json['experiences'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CurriculumItem.fromJson)
          .toList(),
      education: (json['education'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CurriculumItem.fromJson)
          .toList(),
      attachment: CurriculumAttachment.fromJson(
        json['attachment'] as Map<String, dynamic>?,
      ),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'summary': summary,
      'phone': phone,
      'location': location,
      'skills': skills,
      'experiences': experiences.map((item) => item.toJson()).toList(),
      'education': education.map((item) => item.toJson()).toList(),
      if (attachment != null) 'attachment': attachment!.toJson(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

class CurriculumAttachment {
  const CurriculumAttachment({
    required this.fileName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    this.updatedAt,
  });

  final String fileName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final DateTime? updatedAt;

  static CurriculumAttachment? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return CurriculumAttachment(
      fileName: json['file_name'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      updatedAt: Curriculum._parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'storage_path': storagePath,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class CurriculumItem {
  const CurriculumItem({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String period;
  final String description;

  factory CurriculumItem.empty() {
    return const CurriculumItem(
      title: '',
      subtitle: '',
      period: '',
      description: '',
    );
  }

  CurriculumItem copyWith({
    String? title,
    String? subtitle,
    String? period,
    String? description,
  }) {
    return CurriculumItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      period: period ?? this.period,
      description: description ?? this.description,
    );
  }

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    return CurriculumItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      period: json['period'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'period': period,
      'description': description,
    };
  }
}
