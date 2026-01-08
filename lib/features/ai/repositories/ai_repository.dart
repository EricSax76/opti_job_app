import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class AiRepository {
  AiRepository(this._service);

  final AiService _service;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
  }) {
    return _service.improveCurriculumSummary(
      curriculum: curriculum,
      locale: locale,
    );
  }

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
  }) {
    return _service.matchOfferCandidate(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
    );
  }

  Future<AiMatchResult> matchOfferCandidateForCompany({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
  }) {
    return _service.matchOfferCandidateForCompany(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
    );
  }

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) {
    return _service.generateJobOffer(
      criteria: criteria,
      locale: locale,
      quality: quality,
    );
  }
}
