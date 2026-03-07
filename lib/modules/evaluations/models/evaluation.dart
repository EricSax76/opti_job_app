import 'package:cloud_firestore/cloud_firestore.dart';

enum Recommendation {
  strongYes,
  yes,
  neutral,
  no,
  strongNo;

  static Recommendation fromString(String value) {
    return Recommendation.values.firstWhere(
      (e) => e.name == value || e.toSnakeCase() == value,
      orElse: () => Recommendation.neutral,
    );
  }

  String toSnakeCase() {
    return name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }
}

class Evaluation {
  const Evaluation({
    required this.id,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyId,
    required this.evaluatorUid,
    required this.evaluatorName,
    required this.criteria,
    required this.overallScore,
    required this.recommendation,
    required this.comments,
    this.aiAssisted = false,
    this.aiOverridden = false,
    this.aiOriginalScore,
    this.aiExplanation,
    this.createdAt,
  });

  final String id;
  final String applicationId;
  final String jobOfferId;
  final String companyId;
  final String evaluatorUid;
  final String evaluatorName;
  final List<EvaluationCriteria> criteria;
  final double overallScore;
  final Recommendation recommendation;
  final String comments;
  final bool aiAssisted;
  final bool aiOverridden;
  final double? aiOriginalScore;
  final String? aiExplanation;
  final DateTime? createdAt;

  factory Evaluation.fromFirestore(Map<String, dynamic> data) {
    final criteriaRaw = data['criteria'] as List<dynamic>? ?? [];
    return Evaluation(
      id: data['id'] as String? ?? '',
      applicationId: data['applicationId'] as String? ?? '',
      jobOfferId: data['jobOfferId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      evaluatorUid: data['evaluatorUid'] as String? ?? '',
      evaluatorName: data['evaluatorName'] as String? ?? '',
      criteria: criteriaRaw
          .whereType<Map<String, dynamic>>()
          .map(EvaluationCriteria.fromFirestore)
          .toList(),
      overallScore: (data['overallScore'] as num?)?.toDouble() ?? 0.0,
      recommendation: Recommendation.fromString(
        data['recommendation'] as String? ?? '',
      ),
      comments: data['comments'] as String? ?? '',
      aiAssisted: data['aiAssisted'] as bool? ?? false,
      aiOverridden: data['aiOverridden'] as bool? ?? false,
      aiOriginalScore: (data['aiOriginalScore'] as num?)?.toDouble(),
      aiExplanation: data['aiExplanation'] as String?,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'applicationId': applicationId,
      'jobOfferId': jobOfferId,
      'companyId': companyId,
      'evaluatorUid': evaluatorUid,
      'evaluatorName': evaluatorName,
      'criteria': criteria.map((c) => c.toFirestore()).toList(),
      'overallScore': overallScore,
      'recommendation': recommendation.toSnakeCase(),
      'comments': comments,
      'aiAssisted': aiAssisted,
      'aiOverridden': aiOverridden,
      'aiOriginalScore': aiOriginalScore,
      'aiExplanation': aiExplanation,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }
}

class EvaluationCriteria {
  const EvaluationCriteria({
    required this.id,
    required this.name,
    required this.rating,
    required this.weight,
    required this.notes,
  });

  final String id;
  final String name;
  final int rating;
  final double weight;
  final String notes;

  factory EvaluationCriteria.fromFirestore(Map<String, dynamic> data) {
    return EvaluationCriteria(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'weight': weight,
      'notes': notes,
    };
  }
}
