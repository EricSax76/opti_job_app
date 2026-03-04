class ScorecardTemplate {
  const ScorecardTemplate({
    required this.id,
    required this.companyId,
    required this.name,
    required this.criteria,
    required this.createdBy,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String name;
  final List<ScorecardCriteria> criteria;
  final String createdBy;
  final DateTime? createdAt;

  factory ScorecardTemplate.fromFirestore(Map<String, dynamic> data) {
    final criteriaRaw = data['criteria'] as List<dynamic>? ?? [];
    return ScorecardTemplate(
      id: data['id'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      criteria: criteriaRaw
          .whereType<Map<String, dynamic>>()
          .map(ScorecardCriteria.fromFirestore)
          .toList(),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'criteria': criteria.map((c) => c.toFirestore()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as int) * 1000,
      );
    }
    return null;
  }
}

class ScorecardCriteria {
  const ScorecardCriteria({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
  });

  final String id;
  final String name;
  final String description;
  final double weight;

  factory ScorecardCriteria.fromFirestore(Map<String, dynamic> data) {
    return ScorecardCriteria(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'weight': weight,
    };
  }
}
