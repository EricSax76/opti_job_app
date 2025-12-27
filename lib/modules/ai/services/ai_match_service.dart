import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import 'package:opti_job_app/modules/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/ai/mappers/curriculum_compactor.dart';
import 'package:opti_job_app/modules/ai/mappers/job_offer_compactor.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class AiMatchService {
  AiMatchService(
    this._client, {
    CurriculumCompactor? curriculumCompactor,
    JobOfferCompactor? jobOfferCompactor,
  }) : _curriculumCompactor =
           curriculumCompactor ?? const CurriculumCompactor(),
       _jobOfferCompactor = jobOfferCompactor ?? const JobOfferCompactor();

  final FirebaseAiClient _client;
  final CurriculumCompactor _curriculumCompactor;
  final JobOfferCompactor _jobOfferCompactor;

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    try {
      final cv = _curriculumCompactor.compact(curriculum);
      final offerJson = _jobOfferCompactor.compact(offer);
      final prompt = _buildPrompt(
        cv: cv,
        offer: offerJson,
        locale: locale,
        quality: quality,
      );

      final decoded = await _client.generateJson(
        prompt,
        responseSchema: _matchSchema(),
        generationConfig: _jsonConfigForQuality(quality),
      );

      return AiMatchResult.fromJson(decoded);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }

  String _buildPrompt({
    required Map<String, dynamic> cv,
    required Map<String, dynamic> offer,
    required String locale,
    required String quality,
  }) {
    return '''
Evalúa el encaje entre un candidato y una oferta de empleo.

Requisitos:
- Idioma: Español (es-ES). Responde SIEMPRE en castellano y NO uses inglés.
- Locale de referencia: $locale
- Calidad: $quality
- Devuelve JSON válido con (en castellano):
  - score (0..100)
  - reasons (3..7 strings)
  - summary (opcional, 1-2 frases)
  - recommendations (3..6 strings): recomendaciones concretas para el candidato
    (qué mejorar, qué destacar, qué añadir al CV/portfolio, cómo adaptar la postulación).
- No inventes habilidades/experiencias no presentes en el CV o la oferta.
- Enfócate en ayudar al candidato: identifica gaps y acciones sugeridas.

CV (JSON): ${jsonEncode(cv)}
Oferta (JSON): ${jsonEncode(offer)}
''';
  }

  Schema _matchSchema() {
    return Schema.object(
      properties: {
        'score': Schema.integer(minimum: 0, maximum: 100),
        'reasons': Schema.array(
          items: Schema.string(),
          minItems: 3,
          maxItems: 7,
        ),
        'recommendations': Schema.array(
          items: Schema.string(),
          minItems: 3,
          maxItems: 6,
        ),
        'summary': Schema.string(nullable: true),
      },
      optionalProperties: ['summary'],
      propertyOrdering: ['score', 'reasons', 'recommendations', 'summary'],
    );
  }

  GenerationConfig _jsonConfigForQuality(String quality) {
    return switch (quality) {
      'pro' => GenerationConfig(maxOutputTokens: 768, temperature: 0.2),
      _ => GenerationConfig(maxOutputTokens: 512, temperature: 0.2),
    };
  }
}
