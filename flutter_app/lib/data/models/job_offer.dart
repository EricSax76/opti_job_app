class JobOffer {
  const JobOffer({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.location,
    required this.seniority,
    required this.remote,
    required this.skills,
    this.status,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String location;
  final String seniority;
  final bool remote;
  final List<String> skills;
  final String? status;
  final DateTime? createdAt;

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      seniority: json['seniority'] as String? ?? 'mid',
      remote: json['remote'] as bool? ?? false,
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((skill) => skill.toString())
          .toList(),
      status: json['status'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'location': location,
      'seniority': seniority,
      'remote': remote,
      'skills': skills,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  JobOffer copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? location,
    String? seniority,
    bool? remote,
    List<String>? skills,
    String? status,
    DateTime? createdAt,
  }) {
    return JobOffer(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      seniority: seniority ?? this.seniority,
      remote: remote ?? this.remote,
      skills: skills ?? this.skills,
      status: status ?? this.status,
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
