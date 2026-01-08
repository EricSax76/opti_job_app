class AiMatchResult {
  const AiMatchResult({
    required this.score,
    required this.reasons,
    required this.recommendations,
    this.summary,
  });

  /// 0..100
  final int score;
  final List<String> reasons;
  final List<String> recommendations;
  final String? summary;

  factory AiMatchResult.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    final score = _parseScore(rawScore);
    final reasons = (json['reasons'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final recommendations =
        (json['recommendations'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
    final summary = (json['summary'] as String?)?.trim();
    return AiMatchResult(
      score: score,
      reasons: reasons,
      recommendations: recommendations,
      summary: (summary?.isEmpty ?? true) ? null : summary,
    );
  }

  static int _parseScore(dynamic raw) {
    if (raw is int) return raw.clamp(0, 100);
    if (raw is double) {
      final normalized = raw <= 1.0 ? raw * 100.0 : raw;
      return normalized.round().clamp(0, 100);
    }
    if (raw is num) return raw.toInt().clamp(0, 100);
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = double.tryParse(raw.trim());
      if (parsed == null) throw const FormatException('Invalid score');
      final normalized = parsed <= 1.0 ? parsed * 100.0 : parsed;
      return normalized.round().clamp(0, 100);
    }
    throw const FormatException('Missing score');
  }
}
