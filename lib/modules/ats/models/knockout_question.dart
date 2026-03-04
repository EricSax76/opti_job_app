enum KnockoutQuestionType {
  boolean,
  multipleChoice,
  text,
}

class KnockoutQuestion {
  const KnockoutQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.requiredAnswer,
  });

  final String id;
  final String question;
  final KnockoutQuestionType type;
  final List<String>? options;
  final dynamic requiredAnswer; // Puede ser bool o String.

  static KnockoutQuestion fromFirestore(Map<String, dynamic> data) {
    final typeStr = data['type'] as String?;
    final type = KnockoutQuestionType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr?.toLowerCase(),
      orElse: () => KnockoutQuestionType.text,
    );

    return KnockoutQuestion(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      type: type,
      options: (data['options'] as List<dynamic>?)?.cast<String>(),
      // Mantenemos el requiredAnswer tal cual venga parseado por JSON
      requiredAnswer: data['requiredAnswer'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'question': question,
      'type': type == KnockoutQuestionType.multipleChoice
          ? 'multiple_choice'
          : type.name.toLowerCase(),
      if (options != null) 'options': options,
      if (requiredAnswer != null) 'requiredAnswer': requiredAnswer,
    };
  }
}
