import 'package:equatable/equatable.dart';

enum LegalBasis {
  consent,
  legitimateInterest,
  contractual;

  static LegalBasis fromString(String value) {
    return LegalBasis.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LegalBasis.consent,
    );
  }
}

class ConsentRecord extends Equatable {
  const ConsentRecord({
    required this.id,
    required this.candidateUid,
    required this.companyId,
    required this.type,
    this.granted = false,
    this.grantedAt,
    this.expiresAt,
    this.revokedAt,
    this.legalBasis = LegalBasis.consent,
    this.informationNoticeVersion = '1.0',
  });

  final String id;
  final String candidateUid;
  final String companyId;
  final String type;
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final LegalBasis legalBasis;
  final String informationNoticeVersion;

  @override
  List<Object?> get props => [
        id,
        candidateUid,
        companyId,
        type,
        granted,
        grantedAt,
        expiresAt,
        revokedAt,
        legalBasis,
        informationNoticeVersion,
      ];

  factory ConsentRecord.fromJson(Map<String, dynamic> json, {String? id}) {
    return ConsentRecord(
      id: id ?? json['id']?.toString() ?? '',
      candidateUid: json['candidateUid'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      granted: json['granted'] as bool? ?? false,
      grantedAt: _parseDate(json['grantedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      revokedAt: _parseDate(json['revokedAt']),
      legalBasis: LegalBasis.fromString(json['legalBasis'] as String? ?? 'consent'),
      informationNoticeVersion: json['informationNoticeVersion'] as String? ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateUid': candidateUid,
      'companyId': companyId,
      'type': type,
      'granted': granted,
      'legalBasis': legalBasis.name,
      'informationNoticeVersion': informationNoticeVersion,
      if (grantedAt != null) 'grantedAt': grantedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (revokedAt != null) 'revokedAt': revokedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
