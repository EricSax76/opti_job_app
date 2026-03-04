import 'package:equatable/equatable.dart';

class PoolMember extends Equatable {
  const PoolMember({
    required this.candidateUid,
    required this.addedBy,
    required this.addedAt,
    this.tags = const [],
    this.source = 'manual',
    this.sourceApplicationId,
    this.consentGiven = false,
    this.consentAt,
    this.consentExpiresAt,
  });

  final String candidateUid;
  final String addedBy;
  final DateTime addedAt;
  final List<String> tags;
  final String source;
  final String? sourceApplicationId;
  final bool consentGiven;
  final DateTime? consentAt;
  final DateTime? consentExpiresAt;

  @override
  List<Object?> get props => [
        candidateUid,
        addedBy,
        addedAt,
        tags,
        source,
        sourceApplicationId,
        consentGiven,
        consentAt,
        consentExpiresAt,
      ];

  factory PoolMember.fromJson(Map<String, dynamic> json) {
    return PoolMember(
      candidateUid: json['candidateUid'] as String? ?? '',
      addedBy: json['addedBy'] as String? ?? '',
      addedAt: _parseDate(json['addedAt']) ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      source: json['source'] as String? ?? 'manual',
      sourceApplicationId: json['sourceApplicationId'] as String?,
      consentGiven: json['consentGiven'] as bool? ?? false,
      consentAt: _parseDate(json['consentAt']),
      consentExpiresAt: _parseDate(json['consentExpiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateUid': candidateUid,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'tags': tags,
      'source': source,
      'sourceApplicationId': sourceApplicationId,
      'consentGiven': consentGiven,
      if (consentAt != null) 'consentAt': consentAt!.toIso8601String(),
      if (consentExpiresAt != null) 'consentExpiresAt': consentExpiresAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
