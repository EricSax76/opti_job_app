import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import 'package:opti_job_app/modules/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/modules/ai/mappers/ai_criteria_sanitizer.dart';

class AiJobOfferGeneratorService {
  AiJobOfferGeneratorService(
    this._client, {
    AiCriteriaSanitizer? criteriaSanitizer,
  }) : _criteriaSanitizer = criteriaSanitizer ?? const AiCriteriaSanitizer();

  final FirebaseAiClient _client;
  final AiCriteriaSanitizer _criteriaSanitizer;

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    try {
      final compactCriteria = _criteriaSanitizer.compact(criteria);
      final prompt = _buildPrompt(
        criteria: compactCriteria,
        locale: locale,
        quality: quality,
      );

      final decoded = await _client.generateJson(
        prompt,
        responseSchema: _jobOfferSchema(),
        generationConfig: _jsonConfigForQuality(quality),
      );

      return AiJobOfferDraft.fromJson(decoded);
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

  String _buildPrompt({
    required Map<String, dynamic> criteria,
    required String locale,
    required String quality,
  }) {
    return '''
Genera un borrador de oferta de empleo en base a los criterios.

Requisitos:
- Idioma/locale: $locale (escribe todo el texto en este idioma; para es-ES, en castellano)
- Calidad: $quality
- Devuelve JSON válido con los campos:
  - title (string, requerido)
  - description (string, requerido)
  - location (string, requerido)
  - job_type, salary_min, salary_max, education, key_indicators (opcionales)
- No inventes datos concretos (salario, ubicación exacta, tecnologías) si no están en los criterios.
- description debe ser clara y lista para publicar (puede incluir secciones y bullets en texto).

Criterios (JSON): ${jsonEncode(criteria)}
''';
  }

  Schema _jobOfferSchema() {
    return Schema.object(
      properties: {
        'title': Schema.string(),
        'description': Schema.string(),
        'location': Schema.string(),
        'job_type': Schema.string(nullable: true),
        'salary_min': Schema.string(nullable: true),
        'salary_max': Schema.string(nullable: true),
        'education': Schema.string(nullable: true),
        'key_indicators': Schema.string(nullable: true),
      },
      optionalProperties: [
        'job_type',
        'salary_min',
        'salary_max',
        'education',
        'key_indicators',
      ],
      propertyOrdering: [
        'title',
        'description',
        'location',
        'job_type',
        'salary_min',
        'salary_max',
        'education',
        'key_indicators',
      ],
    );
  }

  GenerationConfig _jsonConfigForQuality(String quality) {
    return switch (quality) {
      'pro' => GenerationConfig(maxOutputTokens: 1536, temperature: 0.4),
      _ => GenerationConfig(maxOutputTokens: 1024, temperature: 0.4),
    };
  }
}
