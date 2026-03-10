enum KnockoutQuestionType { boolean, multipleChoice, text }

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
    final typeStr = (data['type']?.toString() ?? '').toLowerCase().trim();
    final type = switch (typeStr) {
      'boolean' => KnockoutQuestionType.boolean,
      'multiple_choice' => KnockoutQuestionType.multipleChoice,
      'multiplechoice' => KnockoutQuestionType.multipleChoice,
      'multiplechoicequestion' => KnockoutQuestionType.multipleChoice,
      'text' => KnockoutQuestionType.text,
      _ => KnockoutQuestionType.text,
    };

    return KnockoutQuestion(
      id: (data['id']?.toString() ?? '').trim(),
      question: (data['question']?.toString() ?? '').trim(),
      type: type,
      options: _parseOptions(data['options']),
      // Mantenemos el requiredAnswer tal cual venga parseado por JSON
      requiredAnswer: data['requiredAnswer'],
    );
  }

  static List<String>? _parseOptions(dynamic value) {
    if (value is! List) return null;
    return value
        .whereType<String>()
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList(growable: false);
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
