import 'package:opti_job_app/modules/ai/api/ai_api_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/mappers/curriculum_compactor.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class AiCvService {
  AiCvService(this._client, {CurriculumCompactor? compactor})
    : _compactor = compactor ?? const CurriculumCompactor();

  final AiApiClient _client;
  final CurriculumCompactor _compactor;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    final payload = <String, dynamic>{
      'cv': _compactor.compact(curriculum),
      'locale': locale,
      'quality': quality,
    };

    final decoded = await _client.postJson(
      '/ai/improve-cv-summary',
      payload: payload,
    );

    final summary = decoded['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const AiRequestException(
        'El servicio de IA no devolvió un resumen.',
      );
    }

    return summary.trim();
  }
}
