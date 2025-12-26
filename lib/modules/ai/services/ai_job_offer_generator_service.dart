import 'package:opti_job_app/modules/ai/api/ai_api_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/modules/ai/mappers/ai_criteria_sanitizer.dart';

class AiJobOfferGeneratorService {
  AiJobOfferGeneratorService(
    this._client, {
    AiCriteriaSanitizer? criteriaSanitizer,
  }) : _criteriaSanitizer = criteriaSanitizer ?? const AiCriteriaSanitizer();

  final AiApiClient _client;
  final AiCriteriaSanitizer _criteriaSanitizer;

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    final payload = <String, dynamic>{
      'criteria': _criteriaSanitizer.compact(criteria),
      'locale': locale,
      'quality': quality,
    };

    final decoded = await _client.postJson(
      '/ai/generate-job-offer',
      payload: payload,
    );

    try {
      return AiJobOfferDraft.fromJson(decoded);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }
}
