enum PipelineStageType {
  newStage,
  screening,
  interview,
  offer,
  hired,
  rejected,
}

class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.name,
    required this.order,
    required this.type,
  });

  final String id;
  final String name;
  final int order;
  final PipelineStageType type;

  static PipelineStage fromFirestore(Map<String, dynamic> data) {
    final typeStr = data['type'] as String?;
    final type = PipelineStageType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr?.toLowerCase(),
      orElse: () => PipelineStageType.newStage,
    );
    return PipelineStage(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      type: type,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'type': type == PipelineStageType.newStage ? 'new' : type.name.toLowerCase(),
    };
  }
}

