import 'package:postgres/postgres.dart';

class JobOffer {
  const JobOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.jobType,
    this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String location;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? jobType;
  final DateTime? createdAt;

  factory JobOffer.fromRow(ResultRow row) {
    final data = row.toColumnMap();
    return JobOffer(
      id: data['id'] is int
          ? data['id'] as int
          : int.parse(data['id'].toString()),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      salaryMin: data['salary_min']?.toString(),
      salaryMax: data['salary_max']?.toString(),
      education: data['education'] as String?,
      jobType: data['job_type'] as String?,
      createdAt: _parseDate(data['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'job_type': jobType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
