class EudiWalletCredentialInput {
  const EudiWalletCredentialInput({
    required this.type,
    required this.title,
    required this.issuer,
    this.issuedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  final String type;
  final String title;
  final String issuer;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'issuer': issuer,
      if (issuedAt != null) 'issuedAt': issuedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

class EudiWalletSignInInput {
  const EudiWalletSignInInput({
    required this.walletSubject,
    required this.email,
    required this.fullName,
    this.countryCode = 'ES',
    this.assuranceLevel = 'substantial',
    this.credential,
  });

  final String walletSubject;
  final String email;
  final String fullName;
  final String countryCode;
  final String assuranceLevel;
  final EudiWalletCredentialInput? credential;

  Map<String, dynamic> toJson() {
    return {
      'walletSubject': walletSubject,
      'email': email,
      'fullName': fullName,
      'countryCode': countryCode,
      'assuranceLevel': assuranceLevel,
      if (credential != null) 'credential': credential!.toJson(),
    };
  }
}

class EudiWalletSignInResult {
  const EudiWalletSignInResult({
    required this.candidateUid,
    required this.provider,
    this.importedCredentialId,
  });

  final String candidateUid;
  final String provider;
  final String? importedCredentialId;
}

class VerifiedCredential {
  const VerifiedCredential({
    required this.id,
    required this.type,
    required this.title,
    required this.issuer,
    required this.verified,
    this.source,
    this.issuedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  final String id;
  final String type;
  final String title;
  final String issuer;
  final bool verified;
  final String? source;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  factory VerifiedCredential.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return VerifiedCredential(
      id: id ?? json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      verified: json['verified'] as bool? ?? true,
      source: json['source'] as String?,
      issuedAt: parseDate(json['issuedAt']),
      expiresAt: parseDate(json['expiresAt']),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }
}
