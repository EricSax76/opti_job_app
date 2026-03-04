class SalaryHistoryGuard {
  const SalaryHistoryGuard._();

  static final List<RegExp> _patterns = <RegExp>[
    RegExp(r'historial\s+salarial', caseSensitive: false),
    RegExp(r'salario\s+(anterior|previo|actual)', caseSensitive: false),
    RegExp(r'sueldo\s+(anterior|previo|actual)', caseSensitive: false),
    RegExp(r'n[oó]mina\s+(anterior|previa|actual)', caseSensitive: false),
    RegExp(
      r'cu[aá]nto\s+(cobrabas|cobraste|ganabas|ganaste)',
      caseSensitive: false,
    ),
    RegExp(r'previous\s+salary', caseSensitive: false),
    RegExp(r'salary\s+history', caseSensitive: false),
    RegExp(r'last\s+salary', caseSensitive: false),
    RegExp(r'prior\s+salary', caseSensitive: false),
    RegExp(r'current\s+salary', caseSensitive: false),
    RegExp(r'payslip', caseSensitive: false),
  ];

  static final List<RegExp> _allowedPatterns = <RegExp>[
    RegExp(r'expectativas?\s+salariales?', caseSensitive: false),
    RegExp(r'salary\s+expectations?', caseSensitive: false),
    RegExp(r'pretensi[oó]n\s+salarial', caseSensitive: false),
  ];

  static bool containsProhibitedPrompt(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    if (_allowedPatterns.any((pattern) => pattern.hasMatch(normalized))) {
      return false;
    }
    return _patterns.any((pattern) => pattern.hasMatch(normalized));
  }

  static bool knockoutQuestionsContainProhibitedPrompt(
    List<dynamic>? knockoutQuestions,
  ) {
    if (knockoutQuestions == null || knockoutQuestions.isEmpty) return false;

    for (final dynamic item in knockoutQuestions) {
      if (item is! Map) continue;
      final rawQuestion = item['question'];
      if (rawQuestion is String && containsProhibitedPrompt(rawQuestion)) {
        return true;
      }
    }
    return false;
  }
}
