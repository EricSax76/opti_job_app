import 'package:firebase_ai/firebase_ai.dart';

import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/mappers/curriculum_compactor.dart';
import 'package:opti_job_app/features/ai/mappers/job_offer_compactor.dart';
import 'package:opti_job_app/features/ai/mappers/skills_compactor.dart';
import 'package:opti_job_app/features/ai/prompts/ai_prompts.dart';
import 'package:opti_job_app/features/ai/prompts/ai_skills_prompts.dart';
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
      final prompt = AiPrompts.matchCandidate(
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
    } on AiRequestException {
      rethrow;
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }

  Future<AiMatchResult> matchOfferCandidateForCompany({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    try {
      final cv = _curriculumCompactor.compact(curriculum);
      final offerJson = _jobOfferCompactor.compact(offer);
      final prompt = AiPrompts.matchCompany(
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
    } on AiRequestException {
      rethrow;
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }

  Future<AiMatchResult> matchOfferCandidateWithSkills({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    try {
      final cv = _curriculumCompactor.compact(curriculum);
      final skills = SkillsCompactor.compact(curriculum.structuredSkills);
      final offerJson = _jobOfferCompactor.compact(offer);
      final offerSkills = SkillsCompactor.compactJobSkills(
        required: offer.requiredSkills,
        preferred: offer.preferredSkills,
      );

      final prompt =
          '''
${AiSkillsPrompts.systemCompliance}
${AiPrompts.matchCandidate(cv: cv, offer: offerJson, locale: locale, quality: quality)}
${AiSkillsPrompts.matchSkills}

Additional Data:
Candidate Skills: $skills
Job Skills: $offerSkills
''';

      final decoded = await _client.generateJson(
        prompt,
        responseSchema: _matchWithSkillsSchema(),
        generationConfig: _jsonConfigForQuality(quality),
      );

      return AiMatchResult.fromJson({
        ...decoded,
        'modelVersion': quality,
        'generatedAt': DateTime.now().toIso8601String(),
      });
    } on AiRequestException {
      rethrow;
    } catch (_) {
      throw const AiRequestException(
        'Respuesta inválida del servicio de IA (Matching Skills).',
      );
    }
  }

  Schema _matchSchema() {
    return Schema.object(
      properties: {
        'score': Schema.integer(minimum: 0, maximum: 100),
        'reasons': Schema.array(items: Schema.string()),
        'recommendations': Schema.array(items: Schema.string()),
        'summary': Schema.string(nullable: true),
      },
      optionalProperties: ['summary'],
      propertyOrdering: ['score', 'reasons', 'recommendations', 'summary'],
    );
  }

  Schema _matchWithSkillsSchema() {
    return Schema.object(
      properties: {
        'score': Schema.integer(minimum: 0, maximum: 100),
        'reasons': Schema.array(items: Schema.string()),
        'recommendations': Schema.array(items: Schema.string()),
        'explanation': Schema.string(),
        'skillsOverlap': Schema.object(
          properties: {
            'matched': Schema.array(items: Schema.string()),
            'missing': Schema.array(items: Schema.string()),
            'adjacent': Schema.array(items: Schema.string()),
          },
        ),
        'summary': Schema.string(nullable: true),
      },
      propertyOrdering: [
        'score',
        'reasons',
        'recommendations',
        'explanation',
        'skillsOverlap',
        'summary',
      ],
    );
  }

  GenerationConfig _jsonConfigForQuality(String quality) {
    return switch (quality) {
      'pro' => GenerationConfig(maxOutputTokens: 768, temperature: 0.2),
      _ => GenerationConfig(maxOutputTokens: 512, temperature: 0.2),
    };
  }
}
