class AiDecisionReview {
  const AiDecisionReview({
    required this.applicationId,
    required this.candidateUid,
    required this.companyId,
    required this.actorScope,
    required this.aiMatchResult,
    required this.humanOverride,
    required this.logs,
  });

  final String applicationId;
  final String candidateUid;
  final String companyId;
  final String actorScope;
  final AiDecisionMatchResult aiMatchResult;
  final AiDecisionHumanOverride humanOverride;
  final List<AiDecisionLogEntry> logs;

  factory AiDecisionReview.fromJson(Map<String, dynamic> json) {
    return AiDecisionReview(
      applicationId: _readString(json['applicationId']),
      candidateUid: _readString(json['candidateUid']),
      companyId: _readString(json['companyId']),
      actorScope: _readString(json['actorScope']),
      aiMatchResult: AiDecisionMatchResult.fromJson(
        _readMap(json['aiMatchResult']),
      ),
      humanOverride: AiDecisionHumanOverride.fromJson(
        _readMap(json['humanOverride']),
      ),
      logs: (_readList(json['logs']))
          .map((item) => AiDecisionLogEntry.fromJson(_readMap(item)))
          .toList(growable: false),
    );
  }
}

class AiDecisionMatchResult {
  const AiDecisionMatchResult({
    required this.score,
    required this.explanation,
    required this.modelVersion,
    required this.generatedAt,
    required this.decisionLogId,
  });

  final double? score;
  final String? explanation;
  final String? modelVersion;
  final DateTime? generatedAt;
  final String? decisionLogId;

  factory AiDecisionMatchResult.fromJson(Map<String, dynamic> json) {
    return AiDecisionMatchResult(
      score: _readNullableDouble(json['score']),
      explanation: _readNullableString(json['explanation']),
      modelVersion: _readNullableString(json['modelVersion']),
      generatedAt: _readNullableDate(json['generatedAt']),
      decisionLogId: _readNullableString(json['decisionLogId']),
    );
  }
}

class AiDecisionHumanOverride {
  const AiDecisionHumanOverride({
    required this.overriddenBy,
    required this.overriddenAt,
    required this.originalAiScore,
    required this.overrideScore,
    required this.reason,
  });

  final String? overriddenBy;
  final DateTime? overriddenAt;
  final double? originalAiScore;
  final double? overrideScore;
  final String? reason;

  factory AiDecisionHumanOverride.fromJson(Map<String, dynamic> json) {
    return AiDecisionHumanOverride(
      overriddenBy: _readNullableString(json['overriddenBy']),
      overriddenAt: _readNullableDate(json['overriddenAt']),
      originalAiScore: _readNullableDouble(json['originalAiScore']),
      overrideScore: _readNullableDouble(json['overrideScore']),
      reason: _readNullableString(json['reason']),
    );
  }

  bool get isOverridden => overriddenAt != null;
}

class AiDecisionLogEntry {
  const AiDecisionLogEntry({
    required this.id,
    required this.decisionType,
    required this.decisionStatus,
    required this.score,
    required this.previousScore,
    required this.actorUid,
    required this.actorRole,
    required this.createdAt,
  });

  final String id;
  final String decisionType;
  final String decisionStatus;
  final double? score;
  final double? previousScore;
  final String actorUid;
  final String actorRole;
  final DateTime? createdAt;

  factory AiDecisionLogEntry.fromJson(Map<String, dynamic> json) {
    return AiDecisionLogEntry(
      id: _readString(json['id']),
      decisionType: _readString(json['decisionType']),
      decisionStatus: _readString(json['decisionStatus']),
      score: _readNullableDouble(json['score']),
      previousScore: _readNullableDouble(json['previousScore']),
      actorUid: _readString(json['actorUid']),
      actorRole: _readString(json['actorRole']),
      createdAt: _readNullableDate(json['createdAt']),
    );
  }
}

class AiDecisionOverrideResult {
  const AiDecisionOverrideResult({
    required this.success,
    required this.applicationId,
    required this.decisionLogId,
    required this.originalAiScore,
    required this.overrideScore,
  });

  final bool success;
  final String applicationId;
  final String decisionLogId;
  final double? originalAiScore;
  final double? overrideScore;

  factory AiDecisionOverrideResult.fromJson(Map<String, dynamic> json) {
    return AiDecisionOverrideResult(
      success: json['success'] == true,
      applicationId: _readString(json['applicationId']),
      decisionLogId: _readString(json['decisionLogId']),
      originalAiScore: _readNullableDouble(json['originalAiScore']),
      overrideScore: _readNullableDouble(json['overrideScore']),
    );
  }
}

String _readString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String? _readNullableString(dynamic value) {
  final normalized = _readString(value);
  return normalized.isEmpty ? null : normalized;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

DateTime? _readNullableDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _readList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}
