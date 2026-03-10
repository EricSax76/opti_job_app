import 'package:cloud_firestore/cloud_firestore.dart';

class CandidatePrivacyExportSummary {
  const CandidatePrivacyExportSummary({
    required this.rawPayload,
    required this.applicationsCount,
    required this.consentsCount,
    required this.notesCount,
    required this.requestsCount,
    required this.exportedAt,
  });

  final Map<String, dynamic> rawPayload;
  final int applicationsCount;
  final int consentsCount;
  final int notesCount;
  final int requestsCount;
  final String? exportedAt;

  factory CandidatePrivacyExportSummary.fromPayload(
    Map<String, dynamic> payload,
  ) {
    int countOf(String key) {
      final raw = payload[key];
      if (raw is List) return raw.length;
      return 0;
    }

    return CandidatePrivacyExportSummary(
      rawPayload: payload,
      applicationsCount: countOf('applications'),
      consentsCount: countOf('consents'),
      notesCount: countOf('candidateNotes'),
      requestsCount: countOf('dataRequests'),
      exportedAt: payload['exportedAt']?.toString(),
    );
  }
}

class CandidateDecisionRequestContext {
  const CandidateDecisionRequestContext({
    required this.id,
    required this.offerTitle,
    required this.status,
    required this.companyId,
    required this.aiExplanation,
    required this.updatedAt,
  });

  final String id;
  final String offerTitle;
  final String status;
  final String? companyId;
  final String? aiExplanation;
  final DateTime? updatedAt;

  bool get isFinalist =>
      status == 'offered' ||
      status == 'hired' ||
      status == 'interviewing' ||
      status == 'finalist';

  String get statusLabel {
    if (status.isEmpty) return 'Sin estado';
    return status.toUpperCase();
  }

  factory CandidateDecisionRequestContext.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final aiMatch =
        (json['aiMatchResult'] as Map<String, dynamic>?) ?? const {};
    final rawStatus = (json['status'] as String? ?? '').trim().toLowerCase();
    final title = (json['jobOfferTitle'] as String?)?.trim();
    final jobOfferId = (json['job_offer_id'] ?? json['jobOfferId'])?.toString();
    final company = (json['company_uid'] ?? json['companyUid'])?.toString();

    return CandidateDecisionRequestContext(
      id: id,
      offerTitle: (title != null && title.isNotEmpty)
          ? title
          : 'Candidatura ${jobOfferId ?? id}',
      status: rawStatus,
      companyId: (company == null || company.trim().isEmpty)
          ? null
          : company.trim(),
      aiExplanation: aiMatch['explanation'] as String?,
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
