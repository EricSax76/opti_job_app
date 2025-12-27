import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:opti_job_app/modules/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/modules/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/modules/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/ai/services/ai_cv_service.dart';
import 'package:opti_job_app/modules/ai/services/ai_job_offer_generator_service.dart';
import 'package:opti_job_app/modules/ai/services/ai_match_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class AiService {
  AiService({FirebaseAI? firebaseAI, FirebaseAuth? auth, String? model})
    : _client = FirebaseAiClient(
        firebaseAI: firebaseAI,
        auth: auth,
        model: model,
      ) {
    _cvService = AiCvService(_client);
    _matchService = AiMatchService(_client);
    _jobOfferGeneratorService = AiJobOfferGeneratorService(_client);
  }

  final FirebaseAiClient _client;
  late final AiCvService _cvService;
  late final AiMatchService _matchService;
  late final AiJobOfferGeneratorService _jobOfferGeneratorService;

  Future<String> improveCurriculumSummary({
    required Curriculum curriculum,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _cvService.improveCurriculumSummary(
      curriculum: curriculum,
      locale: locale,
      quality: quality,
    );
  }

  Future<AiMatchResult> matchOfferCandidate({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _matchService.matchOfferCandidate(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
      quality: quality,
    );
  }

  Future<AiMatchResult> matchOfferCandidateForCompany({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _matchService.matchOfferCandidateForCompany(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
      quality: quality,
    );
  }

  Future<AiJobOfferDraft> generateJobOffer({
    required Map<String, dynamic> criteria,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _jobOfferGeneratorService.generateJobOffer(
      criteria: criteria,
      locale: locale,
      quality: quality,
    );
  }
}
