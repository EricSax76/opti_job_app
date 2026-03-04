class QualifiedSignatureStartResult {
  const QualifiedSignatureStartResult({
    required this.requestId,
    required this.applicationId,
    required this.provider,
    required this.legalFramework,
    required this.documentHash,
    this.expiresAt,
    this.signingChallengeHint,
  });

  final String requestId;
  final String applicationId;
  final String provider;
  final String legalFramework;
  final String documentHash;
  final DateTime? expiresAt;
  final String? signingChallengeHint;

  factory QualifiedSignatureStartResult.fromJson(Map<String, dynamic> json) {
    return QualifiedSignatureStartResult(
      requestId: (json['requestId'] as String?)?.trim() ?? '',
      applicationId: (json['applicationId'] as String?)?.trim() ?? '',
      provider: (json['provider'] as String?)?.trim() ?? '',
      legalFramework: (json['legalFramework'] as String?)?.trim() ?? '',
      documentHash: (json['documentHash'] as String?)?.trim() ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      signingChallengeHint: (json['signingChallengeHint'] as String?)?.trim(),
    );
  }
}

class QualifiedSignatureConfirmResult {
  const QualifiedSignatureConfirmResult({
    required this.success,
    required this.requestId,
    required this.signatureId,
    required this.applicationId,
    required this.status,
    this.legalValidity,
    this.signedAt,
  });

  final bool success;
  final String requestId;
  final String signatureId;
  final String applicationId;
  final String status;
  final String? legalValidity;
  final DateTime? signedAt;

  factory QualifiedSignatureConfirmResult.fromJson(Map<String, dynamic> json) {
    return QualifiedSignatureConfirmResult(
      success: json['success'] == true,
      requestId: (json['requestId'] as String?)?.trim() ?? '',
      signatureId: (json['signatureId'] as String?)?.trim() ?? '',
      applicationId: (json['applicationId'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      legalValidity: (json['legalValidity'] as String?)?.trim(),
      signedAt: _parseDate(json['signedAt']),
    );
  }
}

class QualifiedSignatureStatusResult {
  const QualifiedSignatureStatusResult({
    required this.applicationId,
    required this.status,
    this.contractSignature = const <String, dynamic>{},
  });

  final String applicationId;
  final String status;
  final Map<String, dynamic> contractSignature;

  factory QualifiedSignatureStatusResult.fromJson(Map<String, dynamic> json) {
    final signature = json['contractSignature'];
    return QualifiedSignatureStatusResult(
      applicationId: (json['applicationId'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      contractSignature: signature is Map<String, dynamic>
          ? signature
          : signature is Map
          ? Map<String, dynamic>.from(signature)
          : const <String, dynamic>{},
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
