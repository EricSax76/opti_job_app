import 'package:opti_job_app/modules/ai/api/ai_api_client.dart';
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

  final AiApiClient _client;
  final CurriculumCompactor _curriculumCompactor;
  final JobOfferCompactor _jobOfferCompactor;

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    final payload = <String, dynamic>{
      'cv': _curriculumCompactor.compact(curriculum),
      'offer': _jobOfferCompactor.compact(offer),
      'locale': locale,
      'quality': quality,
    };

    final decoded = await _client.postJson(
      '/ai/match-offer-candidate',
      payload: payload,
    );

    try {
      return AiMatchResult.fromJson(decoded);
    } catch (_) {
      throw const AiRequestException('Respuesta inválida del servicio de IA.');
    }
  }
}
