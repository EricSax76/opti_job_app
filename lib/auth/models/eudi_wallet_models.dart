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

class EudiPresentationRequest {
  const EudiPresentationRequest({
    required this.purpose,
    required this.audience,
    required this.requestedCredentialTypes,
    required this.proofSchemaVersion,
    this.nonce,
    this.constraints = const {},
  });

  final String purpose;
  final String audience;
  final List<String> requestedCredentialTypes;
  final String proofSchemaVersion;
  final String? nonce;
  final Map<String, dynamic> constraints;

  factory EudiPresentationRequest.forSignIn({
    String audience = 'opti-job-app:eudi-signin',
    String proofSchemaVersion = '2026.1',
    String? nonce,
  }) {
    return EudiPresentationRequest(
      purpose: 'signin',
      audience: audience,
      requestedCredentialTypes: const ['IdentityCredential'],
      proofSchemaVersion: proofSchemaVersion,
      nonce: nonce,
      constraints: const {'requireIdentityClaims': true},
    );
  }

  factory EudiPresentationRequest.forCredentialImport({
    String audience = 'opti-job-app:eudi-import',
    String proofSchemaVersion = '2026.1',
    String? nonce,
  }) {
    return EudiPresentationRequest(
      purpose: 'credential_import',
      audience: audience,
      requestedCredentialTypes: const [
        'EducationCredential',
        'ProfessionalCertification',
        'EmploymentCredential',
      ],
      proofSchemaVersion: proofSchemaVersion,
      nonce: nonce,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purpose': purpose,
      'audience': audience,
      'requestedCredentialTypes': requestedCredentialTypes,
      'proofSchemaVersion': proofSchemaVersion,
      if (nonce != null && nonce!.trim().isNotEmpty) 'nonce': nonce!.trim(),
      if (constraints.isNotEmpty) 'constraints': constraints,
    };
  }
}

class EudiWalletPresentationResponse {
  const EudiWalletPresentationResponse({
    required this.walletSubject,
    required this.verifiablePresentation,
    required this.verificationMethod,
    required this.issuerDid,
    required this.credentialType,
    required this.proofSchemaVersion,
    this.email,
    this.fullName,
    this.countryCode = 'ES',
    this.assuranceLevel = 'substantial',
    this.credential,
  });

  final String walletSubject;
  final String verifiablePresentation;
  final String verificationMethod;
  final String issuerDid;
  final String credentialType;
  final String proofSchemaVersion;
  final String? email;
  final String? fullName;
  final String countryCode;
  final String assuranceLevel;
  final EudiWalletCredentialInput? credential;

  factory EudiWalletPresentationResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final credentialRaw = json['credential'];
    EudiWalletCredentialInput? credential;
    if (credentialRaw is Map) {
      final credentialMap = Map<String, dynamic>.from(credentialRaw);
      final type = credentialMap['type']?.toString().trim() ?? '';
      final title = credentialMap['title']?.toString().trim() ?? '';
      final issuer = credentialMap['issuer']?.toString().trim() ?? '';
      if (type.isNotEmpty && title.isNotEmpty && issuer.isNotEmpty) {
        credential = EudiWalletCredentialInput(
          type: type,
          title: title,
          issuer: issuer,
          issuedAt: parseDate(credentialMap['issuedAt']),
          expiresAt: parseDate(credentialMap['expiresAt']),
          metadata: Map<String, dynamic>.from(
            (credentialMap['metadata'] as Map?) ?? const <String, dynamic>{},
          ),
        );
      }
    }

    return EudiWalletPresentationResponse(
      walletSubject: json['walletSubject']?.toString().trim() ?? '',
      email: json['email']?.toString(),
      fullName: json['fullName']?.toString(),
      countryCode: json['countryCode']?.toString().trim().isNotEmpty == true
          ? json['countryCode'].toString().trim().toUpperCase()
          : 'ES',
      assuranceLevel:
          json['assuranceLevel']?.toString().trim().isNotEmpty == true
          ? json['assuranceLevel'].toString().trim()
          : 'substantial',
      verifiablePresentation:
          json['verifiablePresentation']?.toString().trim() ?? '',
      verificationMethod:
          json['verificationMethod']?.toString().trim().isNotEmpty == true
          ? json['verificationMethod'].toString().trim()
          : 'jws:unknown',
      issuerDid: json['issuerDid']?.toString().trim() ?? '',
      credentialType:
          json['credentialType']?.toString().trim().isNotEmpty == true
          ? json['credentialType'].toString().trim()
          : 'verifiable_credential',
      proofSchemaVersion:
          json['proofSchemaVersion']?.toString().trim().isNotEmpty == true
          ? json['proofSchemaVersion'].toString().trim()
          : '2026.1',
      credential: credential,
    );
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
    this.verifiablePresentation,
    this.expectedAudience,
    this.proofSchemaVersion = '2026.1',
    this.verificationMethod,
    this.issuerDid,
    this.credentialType,
  });

  final String walletSubject;
  final String email;
  final String fullName;
  final String countryCode;
  final String assuranceLevel;
  final EudiWalletCredentialInput? credential;
  final String? verifiablePresentation;
  final String? expectedAudience;
  final String proofSchemaVersion;
  final String? verificationMethod;
  final String? issuerDid;
  final String? credentialType;

  Map<String, dynamic> toJson() {
    return {
      'walletSubject': walletSubject,
      'email': email,
      'fullName': fullName,
      'countryCode': countryCode,
      'assuranceLevel': assuranceLevel,
      if (credential != null) 'credential': credential!.toJson(),
      if (verifiablePresentation != null &&
          verifiablePresentation!.trim().isNotEmpty)
        'verifiablePresentation': verifiablePresentation!.trim(),
      if (expectedAudience != null && expectedAudience!.trim().isNotEmpty)
        'expectedAudience': expectedAudience!.trim(),
      if (proofSchemaVersion.trim().isNotEmpty)
        'proofSchemaVersion': proofSchemaVersion.trim(),
      if (verificationMethod != null && verificationMethod!.trim().isNotEmpty)
        'verificationMethod': verificationMethod!.trim(),
      if (issuerDid != null && issuerDid!.trim().isNotEmpty)
        'issuerDid': issuerDid!.trim(),
      if (credentialType != null && credentialType!.trim().isNotEmpty)
        'credentialType': credentialType!.trim(),
    };
  }
}

class EudiCredentialImportInput {
  const EudiCredentialImportInput({
    required this.verifiablePresentation,
    this.expectedAudience = 'opti-job-app:eudi-import',
    this.proofSchemaVersion = '2026.1',
  });

  final String verifiablePresentation;
  final String expectedAudience;
  final String proofSchemaVersion;

  Map<String, dynamic> toJson() {
    return {
      'verifiablePresentation': verifiablePresentation,
      'expectedAudience': expectedAudience,
      'proofSchemaVersion': proofSchemaVersion,
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
    this.verificationMethod,
    this.issuerDid,
    this.credentialType,
    this.proofSchemaVersion,
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
  final String? verificationMethod;
  final String? issuerDid;
  final String? credentialType;
  final String? proofSchemaVersion;

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
      verificationMethod: json['verificationMethod']?.toString(),
      issuerDid: json['issuerDid']?.toString(),
      credentialType: json['credentialType']?.toString(),
      proofSchemaVersion: json['proofSchemaVersion']?.toString(),
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
    this.proofSchemaVersion,
    this.verificationMethod,
    this.issuerDid,
    this.credentialType,
  });

  final String proofId;
  final String proofToken;
  final String disclosureMode;
  final String statement;
  final String? companyUid;
  final String? applicationId;
  final DateTime? expiresAt;
  final String? proofSchemaVersion;
  final String? verificationMethod;
  final String? issuerDid;
  final String? credentialType;

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
      proofSchemaVersion: json['proofSchemaVersion']?.toString(),
      verificationMethod: json['verificationMethod']?.toString(),
      issuerDid: json['issuerDid']?.toString(),
      credentialType: json['credentialType']?.toString(),
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
    this.proofSchemaVersion,
    this.verificationMethod,
    this.issuerDid,
    this.credentialType,
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
  final String? proofSchemaVersion;
  final String? verificationMethod;
  final String? issuerDid;
  final String? credentialType;

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
      proofSchemaVersion: json['proofSchemaVersion']?.toString(),
      verificationMethod: json['verificationMethod']?.toString(),
      issuerDid: json['issuerDid']?.toString(),
      credentialType: json['credentialType']?.toString(),
    );
  }
}
