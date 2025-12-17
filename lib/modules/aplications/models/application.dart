import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  const Application({
    this.id,
    required this.jobOfferId,
    required this.candidateId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final int jobOfferId;
  final int candidateId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Application.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Application(
      id: id,
      jobOfferId: parseInt(json['job_offer_id']),
      candidateId: parseInt(json['candidate_id']),
      status: json['status'] as String? ?? 'pending',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_offer_id': jobOfferId,
      'candidate_id': candidateId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Application copyWith({
    String? id,
    int? jobOfferId,
    int? candidateId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      jobOfferId: jobOfferId ?? this.jobOfferId,
      candidateId: candidateId ?? this.candidateId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
