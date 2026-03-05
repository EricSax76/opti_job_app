import 'package:equatable/equatable.dart';

class CompanyComplianceProfile extends Equatable {
  const CompanyComplianceProfile({
    this.controllerLegalName = '',
    this.controllerTaxId = '',
    this.privacyContactEmail = '',
    this.dpoName = '',
    this.dpoEmail = '',
    this.privacyPolicyUrl = '',
    this.retentionPolicySummary = '',
    this.internationalTransfersSummary = '',
    this.aiConsentTextVersion = '2026.04',
    this.aiConsentText = _defaultAiConsentText,
  });

  static const String _defaultAiConsentText =
      'Autorizo el uso de sistemas de IA para test y entrevistas de esta candidatura. '
      'Entiendo que puedo solicitar revisión humana y revocar en el portal de privacidad.';

  final String controllerLegalName;
  final String controllerTaxId;
  final String privacyContactEmail;
  final String dpoName;
  final String dpoEmail;
  final String privacyPolicyUrl;
  final String retentionPolicySummary;
  final String internationalTransfersSummary;
  final String aiConsentTextVersion;
  final String aiConsentText;

  bool get isComplete {
    return controllerLegalName.trim().isNotEmpty &&
        controllerTaxId.trim().isNotEmpty &&
        _isValidEmail(privacyContactEmail) &&
        dpoName.trim().isNotEmpty &&
        _isValidEmail(dpoEmail) &&
        privacyPolicyUrl.trim().isNotEmpty &&
        aiConsentTextVersion.trim().isNotEmpty &&
        aiConsentText.trim().isNotEmpty &&
        retentionPolicySummary.trim().isNotEmpty;
  }

  factory CompanyComplianceProfile.fromJson(Object? raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
    return CompanyComplianceProfile(
      controllerLegalName: _readTrimmed(
        map,
        ['controller_legal_name', 'controllerLegalName'],
      ),
      controllerTaxId: _readTrimmed(
        map,
        ['controller_tax_id', 'controllerTaxId'],
      ),
      privacyContactEmail: _readTrimmed(
        map,
        ['privacy_contact_email', 'privacyContactEmail'],
      ),
      dpoName: _readTrimmed(map, ['dpo_name', 'dpoName']),
      dpoEmail: _readTrimmed(map, ['dpo_email', 'dpoEmail']),
      privacyPolicyUrl: _readTrimmed(
        map,
        ['privacy_policy_url', 'privacyPolicyUrl'],
      ),
      retentionPolicySummary: _readTrimmed(
        map,
        ['retention_policy_summary', 'retentionPolicySummary'],
      ),
      internationalTransfersSummary: _readTrimmed(
        map,
        [
          'international_transfers_summary',
          'internationalTransfersSummary',
        ],
      ),
      aiConsentTextVersion: _readTrimmed(
        map,
        ['ai_consent_text_version', 'aiConsentTextVersion'],
        fallback: '2026.04',
      ),
      aiConsentText: _readTrimmed(
        map,
        ['ai_consent_text', 'aiConsentText'],
        fallback: _defaultAiConsentText,
      ),
    );
  }

  CompanyComplianceProfile copyWith({
    String? controllerLegalName,
    String? controllerTaxId,
    String? privacyContactEmail,
    String? dpoName,
    String? dpoEmail,
    String? privacyPolicyUrl,
    String? retentionPolicySummary,
    String? internationalTransfersSummary,
    String? aiConsentTextVersion,
    String? aiConsentText,
  }) {
    return CompanyComplianceProfile(
      controllerLegalName: controllerLegalName ?? this.controllerLegalName,
      controllerTaxId: controllerTaxId ?? this.controllerTaxId,
      privacyContactEmail: privacyContactEmail ?? this.privacyContactEmail,
      dpoName: dpoName ?? this.dpoName,
      dpoEmail: dpoEmail ?? this.dpoEmail,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      retentionPolicySummary:
          retentionPolicySummary ?? this.retentionPolicySummary,
      internationalTransfersSummary: internationalTransfersSummary ??
          this.internationalTransfersSummary,
      aiConsentTextVersion: aiConsentTextVersion ?? this.aiConsentTextVersion,
      aiConsentText: aiConsentText ?? this.aiConsentText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'controller_legal_name': controllerLegalName.trim(),
      'controller_tax_id': controllerTaxId.trim(),
      'privacy_contact_email': privacyContactEmail.trim().toLowerCase(),
      'dpo_name': dpoName.trim(),
      'dpo_email': dpoEmail.trim().toLowerCase(),
      'privacy_policy_url': privacyPolicyUrl.trim(),
      'retention_policy_summary': retentionPolicySummary.trim(),
      'international_transfers_summary': internationalTransfersSummary.trim(),
      'ai_consent_text_version': aiConsentTextVersion.trim(),
      'ai_consent_text': aiConsentText.trim(),
    };
  }

  static bool _isValidEmail(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailPattern.hasMatch(normalized);
  }

  @override
  List<Object?> get props => [
    controllerLegalName,
    controllerTaxId,
    privacyContactEmail,
    dpoName,
    dpoEmail,
    privacyPolicyUrl,
    retentionPolicySummary,
    internationalTransfersSummary,
    aiConsentTextVersion,
    aiConsentText,
  ];
}

String _readTrimmed(
  Map<String, dynamic>? map,
  List<String> keys, {
  String fallback = '',
}) {
  if (map == null) return fallback;

  for (final key in keys) {
    final raw = map[key];
    if (raw == null) continue;
    final normalized = raw.toString().trim();
    if (normalized.isNotEmpty) return normalized;
  }

  return fallback;
}
