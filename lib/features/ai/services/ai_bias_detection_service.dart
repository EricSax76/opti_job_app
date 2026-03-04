import 'package:firebase_ai/firebase_ai.dart';

import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/prompts/ai_bias_prompts.dart';
import 'package:opti_job_app/features/ai/services/ai_schema_factory.dart';

class AiBiasDetectionService {
  const AiBiasDetectionService(this._client);

  final FirebaseAiClient _client;

  Future<Map<String, dynamic>> checkJobOfferBias({
    required String title,
    required String description,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    if (title.trim().isEmpty && description.trim().isEmpty) {
      throw const AiRequestException(
        'El titulo y la descripcion no pueden estar vacios.',
      );
    }

    final prompt = AiBiasPrompts.checkJobOfferBias(
      title: title,
      description: description,
      locale: locale,
    );

    try {
      final decoded = await _client.generateJson(
        prompt,
        responseSchema: AiSchemaFactory.biasCheckSchema(),
        generationConfig: _jsonConfigForQuality(quality),
      );

      return {
        'score': _parseScore(decoded['score']),
        'issues': _parseIssues(decoded['issues']),
        'checkedAt': DateTime.now().toIso8601String(),
      };
    } on AiRequestException {
      rethrow;
    } catch (_) {
      throw const AiRequestException('Respuesta invalida del servicio de IA.');
    }
  }

  GenerationConfig _jsonConfigForQuality(String quality) {
    return switch (quality) {
      'pro' => GenerationConfig(maxOutputTokens: 512, temperature: 0.1),
      _ => GenerationConfig(maxOutputTokens: 320, temperature: 0.1),
    };
  }

  int _parseScore(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed.clamp(0, 100);
    }
    return 0;
  }

  List<String> _parseIssues(dynamic value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
