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

    final error = (decoded['error'] is String)
        ? (decoded['error'] as String).trim()
        : '';
    if (error.isNotEmpty) {
      throw AiRequestException(_mapError(error));
    }

    final draftJson = switch (decoded['draft']) {
      final Map<String, dynamic> m => m,
      _ => decoded,
    };

    try {
      return AiJobOfferDraft.fromJson(draftJson);
    } on FormatException catch (e) {
      final details = e.message.trim();
      throw AiRequestException(
        details.isEmpty
            ? 'La IA devolvió un borrador incompleto. Intenta nuevamente.'
            : 'La IA devolvió un borrador incompleto ($details).',
      );
    } catch (_) {
      throw const AiRequestException(
        'Respuesta inválida del servicio de IA. Intenta nuevamente.',
      );
    }
  }

  String _mapError(String error) {
    switch (error) {
      case 'missing_role':
        return 'Falta el puesto/rol para generar la oferta.';
      case 'invalid_model_output':
        return 'La IA devolvió una respuesta incompleta. Intenta nuevamente.';
      case 'ai_failed':
        return 'No se pudo generar la oferta con IA. Intenta nuevamente.';
      default:
        return 'Error del servicio de IA: $error';
    }
  }
}
