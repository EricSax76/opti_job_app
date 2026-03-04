import 'package:opti_job_app/modules/ats/models/pipeline_stage.dart';

class Pipeline {
  const Pipeline({
    required this.id,
    required this.companyId,
    required this.name,
    required this.stages,
    required this.isTemplate,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final List<PipelineStage> stages;
  final bool isTemplate;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Pipeline fromFirestore(Map<String, dynamic> data) {
    final stagesRaw = data['stages'] as List<dynamic>? ?? [];
    return Pipeline(
      id: data['id'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      stages: stagesRaw
          .whereType<Map<String, dynamic>>()
          .map(PipelineStage.fromFirestore)
          .toList(),
      isTemplate: data['isTemplate'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'stages': stages.map((s) => s.toFirestore()).toList(),
      'isTemplate': isTemplate,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
