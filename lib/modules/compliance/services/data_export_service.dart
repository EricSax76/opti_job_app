import 'dart:convert';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class DataExportService {
  /// Generates a JSON string representing all relevant candidate data for portability.
  String generateJsonExport({
    required String candidateUid,
    required Curriculum curriculum,
    required List<dynamic> applications,
    required List<dynamic> consents,
  }) {
    final exportData = {
      'candidateUid': candidateUid,
      'exportTimestamp': DateTime.now().toIso8601String(),
      'curriculum': curriculum.toJson(),
      'applications': applications.map((a) => a.toJson()).toList(),
      'consents': consents.map((c) => c.toJson()).toList(),
      'legal_notice': 'This data is provided for portability purposes under RGPD Art. 20.',
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // Note: PDF generation would require a library like 'pdf' or 'printing'.
}
