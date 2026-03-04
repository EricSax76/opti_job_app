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

class SelectiveDisclosureProofInput {
  const SelectiveDisclosureProofInput({
    required this.credentialId,
    this.claimKey = 'type',
    this.statement,
    this.applicationId,
    this.audienceCompanyUid,
    this.expiresInMinutes = 60,
  });

  final String credentialId;
  final String claimKey;
  final String? statement;
  final String? applicationId;
  final String? audienceCompanyUid;
  final int expiresInMinutes;

  Map<String, dynamic> toJson() {
    return {
      'credentialId': credentialId,
      'claimKey': claimKey,
      if (statement != null && statement!.trim().isNotEmpty)
        'statement': statement!.trim(),
      if (applicationId != null && applicationId!.trim().isNotEmpty)
        'applicationId': applicationId!.trim(),
      if (audienceCompanyUid != null && audienceCompanyUid!.trim().isNotEmpty)
        'audienceCompanyUid': audienceCompanyUid!.trim(),
      'expiresInMinutes': expiresInMinutes,
    };
  }
}

class SelectiveDisclosureProofResult {
  const SelectiveDisclosureProofResult({
    required this.proofId,
    required this.proofToken,
    required this.disclosureMode,
    required this.statement,
    this.companyUid,
    this.applicationId,
    this.expiresAt,
  });

  final String proofId;
  final String proofToken;
  final String disclosureMode;
  final String statement;
  final String? companyUid;
  final String? applicationId;
  final DateTime? expiresAt;

  factory SelectiveDisclosureProofResult.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SelectiveDisclosureProofResult(
      proofId: json['proofId']?.toString() ?? '',
      proofToken: json['proofToken']?.toString() ?? '',
      disclosureMode:
          json['disclosureMode']?.toString().trim().isNotEmpty == true
          ? json['disclosureMode'].toString().trim()
          : 'zkp_selective',
      statement: json['statement']?.toString() ?? '',
      companyUid: json['companyUid']?.toString(),
      applicationId: json['applicationId']?.toString(),
      expiresAt: parseDate(json['expiresAt']),
    );
  }
}

class SelectiveDisclosureVerificationResult {
  const SelectiveDisclosureVerificationResult({
    required this.verified,
    required this.proofId,
    required this.disclosureMode,
    required this.statement,
    this.candidateUid,
    this.applicationId,
    this.jobOfferId,
    this.companyUid,
    this.claimKey,
    this.expiresAt,
    this.verifiedAt,
  });

  final bool verified;
  final String proofId;
  final String disclosureMode;
  final String statement;
  final String? candidateUid;
  final String? applicationId;
  final String? jobOfferId;
  final String? companyUid;
  final String? claimKey;
  final DateTime? expiresAt;
  final DateTime? verifiedAt;

  factory SelectiveDisclosureVerificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SelectiveDisclosureVerificationResult(
      verified: json['verified'] == true,
      proofId: json['proofId']?.toString() ?? '',
      disclosureMode:
          json['disclosureMode']?.toString().trim().isNotEmpty == true
          ? json['disclosureMode'].toString().trim()
          : 'zkp_selective',
      statement: json['statement']?.toString() ?? '',
      candidateUid: json['candidateUid']?.toString(),
      applicationId: json['applicationId']?.toString(),
      jobOfferId: json['jobOfferId']?.toString(),
      companyUid: json['companyUid']?.toString(),
      claimKey: json['claimKey']?.toString(),
      expiresAt: parseDate(json['expiresAt']),
      verifiedAt: parseDate(json['verifiedAt']),
    );
  }
}
