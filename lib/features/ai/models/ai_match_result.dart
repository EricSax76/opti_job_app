class AiMatchResult {
  const AiMatchResult({
    required this.score,
    required this.reasons,
    required this.recommendations,
    required this.explanation,
    this.skillsOverlap,
    this.skillRoadmap = const [],
    this.projectedScore,
    this.summary,
    this.modelVersion,
    this.generatedAt,
  });

  /// 0..100
  final int score;
  final List<String> reasons;
  final List<String> recommendations;
  final String explanation;
  final SkillsOverlap? skillsOverlap;
  final List<SkillImpactRecommendation> skillRoadmap;
  final int? projectedScore;
  final String? summary;
  final String? modelVersion;
  final DateTime? generatedAt;

  AiMatchResult copyWith({
    int? score,
    List<String>? reasons,
    List<String>? recommendations,
    String? explanation,
    SkillsOverlap? skillsOverlap,
    List<SkillImpactRecommendation>? skillRoadmap,
    int? projectedScore,
    String? summary,
    String? modelVersion,
    DateTime? generatedAt,
    bool clearSummary = false,
    bool clearSkillsOverlap = false,
    bool clearSkillRoadmap = false,
    bool clearProjectedScore = false,
  }) {
    return AiMatchResult(
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
      recommendations: recommendations ?? this.recommendations,
      explanation: explanation ?? this.explanation,
      skillsOverlap: clearSkillsOverlap
          ? null
          : skillsOverlap ?? this.skillsOverlap,
      skillRoadmap: clearSkillRoadmap
          ? const []
          : skillRoadmap ?? this.skillRoadmap,
      projectedScore: clearProjectedScore
          ? null
          : projectedScore ?? this.projectedScore,
      summary: clearSummary ? null : summary ?? this.summary,
      modelVersion: modelVersion ?? this.modelVersion,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

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
      explanation: json['explanation'] as String? ?? '',
      skillsOverlap: json['skillsOverlap'] != null
          ? SkillsOverlap.fromJson(
              json['skillsOverlap'] as Map<String, dynamic>,
            )
          : null,
      skillRoadmap: (json['skillRoadmap'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(SkillImpactRecommendation.fromJson)
          .toList(growable: false),
      projectedScore: _parseOptionalScore(json['projectedScore']),
      summary: (summary?.isEmpty ?? true) ? null : summary,
      modelVersion: json['modelVersion'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'reasons': reasons,
      'recommendations': recommendations,
      'explanation': explanation,
      if (skillsOverlap != null) 'skillsOverlap': skillsOverlap!.toJson(),
      if (skillRoadmap.isNotEmpty)
        'skillRoadmap': skillRoadmap.map((item) => item.toJson()).toList(),
      if (projectedScore != null) 'projectedScore': projectedScore,
      'summary': summary,
      'modelVersion': modelVersion,
      'generatedAt': generatedAt?.toIso8601String(),
    };
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

  static int? _parseOptionalScore(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw.clamp(0, 100);
    if (raw is num) return raw.round().clamp(0, 100);
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = num.tryParse(raw.trim());
      if (parsed == null) return null;
      return parsed.round().clamp(0, 100);
    }
    return null;
  }
}

class SkillsOverlap {
  const SkillsOverlap({
    this.matched = const [],
    this.missing = const [],
    this.adjacent = const [],
  });

  final List<String> matched;
  final List<String> missing;
  final List<String> adjacent;

  factory SkillsOverlap.fromJson(Map<String, dynamic> json) {
    return SkillsOverlap(
      matched: (json['matched'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      missing: (json['missing'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      adjacent: (json['adjacent'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'matched': matched, 'missing': missing, 'adjacent': adjacent};
  }
}

class SkillImpactRecommendation {
  const SkillImpactRecommendation({
    required this.skill,
    required this.estimatedScoreDelta,
    required this.rationale,
    this.currentAdjacentEvidence,
    this.priority = 1,
  });

  final String skill;
  final int estimatedScoreDelta;
  final String rationale;
  final String? currentAdjacentEvidence;
  final int priority;

  factory SkillImpactRecommendation.fromJson(Map<String, dynamic> json) {
    final rawDelta = json['estimatedScoreDelta'];
    final delta = rawDelta is int
        ? rawDelta
        : (rawDelta is num ? rawDelta.round() : 0);
    final rawPriority = json['priority'];
    final priority = rawPriority is int
        ? rawPriority
        : (rawPriority is num ? rawPriority.round() : 1);

    return SkillImpactRecommendation(
      skill: json['skill'] as String? ?? '',
      estimatedScoreDelta: delta,
      rationale: json['rationale'] as String? ?? '',
      currentAdjacentEvidence: json['currentAdjacentEvidence'] as String?,
      priority: priority.clamp(1, 5),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'estimatedScoreDelta': estimatedScoreDelta,
      'rationale': rationale,
      if (currentAdjacentEvidence != null)
        'currentAdjacentEvidence': currentAdjacentEvidence,
      'priority': priority,
    };
  }
}
