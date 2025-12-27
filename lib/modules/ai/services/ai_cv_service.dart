import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import 'package:opti_job_app/modules/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/mappers/curriculum_compactor.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class AiCvService {
  AiCvService(this._client, {CurriculumCompactor? compactor})
    : _compactor = compactor ?? const CurriculumCompactor();

  final FirebaseAiClient _client;
  final CurriculumCompactor _compactor;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    final cv = _compactor.compact(curriculum);
    final prompt = _buildPrompt(cv: cv, locale: locale, quality: quality);
    final summary = await _client.generateText(
      prompt,
      generationConfig: _textConfigForQuality(quality),
    );
    final trimmed = summary.trim();
    if (trimmed.isEmpty) {
      throw const AiRequestException(
        'El servicio de IA no devolvió un resumen.',
      );
    }
    return trimmed;
  }

  String _buildPrompt({
    required Map<String, dynamic> cv,
    required String locale,
    required String quality,
  }) {
    final cvJson = jsonEncode(cv);
    return '''
Reescribe y mejora el resumen profesional del CV.

Requisitos:
- Idioma/locale: $locale
- Calidad: $quality
- Devuelve SOLO el texto final del resumen (sin JSON, sin comillas, sin Markdown).
- 60–120 palabras.
- No inventes datos; si falta información, generaliza sin afirmar cosas específicas.

CV (JSON):
$cvJson
''';
  }

  GenerationConfig _textConfigForQuality(String quality) {
    return switch (quality) {
      'pro' => GenerationConfig(maxOutputTokens: 512, temperature: 0.4),
      _ => GenerationConfig(maxOutputTokens: 320, temperature: 0.4),
    };
  }
}
