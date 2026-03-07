import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TalentPool extends Equatable {
  const TalentPool({
    required this.id,
    required this.companyId,
    required this.name,
    required this.description,
    this.tags = const [],
    this.memberCount = 0,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String description;
  final List<String> tags;
  final int memberCount;
  final String createdBy;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    companyId,
    name,
    description,
    tags,
    memberCount,
    createdBy,
    createdAt,
  ];

  factory TalentPool.fromJson(Map<String, dynamic> json, {String? id}) {
    return TalentPool(
      id: id ?? json['id']?.toString() ?? '',
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'name': name,
      'description': description,
      'tags': tags,
      'memberCount': memberCount,
      'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }
}
