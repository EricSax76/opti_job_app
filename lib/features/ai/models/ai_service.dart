import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/services/ai_cv_service.dart';
import 'package:opti_job_app/features/ai/services/ai_job_offer_generator_service.dart';
import 'package:opti_job_app/features/ai/services/ai_match_service.dart';
import 'package:opti_job_app/features/ai/services/ai_bias_detection_service.dart';
import 'package:opti_job_app/features/ai/services/ai_skills_matching_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

class AiService {
  AiService({required FirebaseAiClient client}) : _client = client {
    _cvService = AiCvService(_client);
    _matchService = AiMatchService(_client);
    _jobOfferGeneratorService = AiJobOfferGeneratorService(_client);
    _biasDetectionService = AiBiasDetectionService(_client);
    _skillsMatchingService = AiSkillsMatchingService(_client);
  }

  final FirebaseAiClient _client;
  late final AiCvService _cvService;
  late final AiMatchService _matchService;
  late final AiJobOfferGeneratorService _jobOfferGeneratorService;
  late final AiBiasDetectionService _biasDetectionService;
  late final AiSkillsMatchingService _skillsMatchingService;

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

  Future<String> improveCoverLetter({
    required Curriculum curriculum,
    required String coverLetterText,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _cvService.improveCoverLetter(
      curriculum: curriculum,
      coverLetterText: coverLetterText,
      locale: locale,
      quality: quality,
    );
  }

  Future<Map<String, dynamic>> checkJobOfferBias({
    required String title,
    required String description,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _biasDetectionService.checkJobOfferBias(
      title: title,
      description: description,
      locale: locale,
      quality: quality,
    );
  }

  Future<AiMatchResult> matchWithSkills({
    required Curriculum curriculum,
    required JobOffer offer,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _matchService.matchOfferCandidateWithSkills(
      curriculum: curriculum,
      offer: offer,
      locale: locale,
      quality: quality,
    );
  }

  Future<List<Skill>> extractSkillsFromCv({
    required String cvText,
    String locale = 'es-ES',
    String quality = 'flash',
  }) async {
    return _skillsMatchingService.extractSkillsFromText(cvText);
  }

  Future<SemanticSkillsMatch> evaluateSemanticSkills({
    required List<Skill> candidateSkills,
    required List<JobOfferSkill> requiredSkills,
    required List<Skill> preferredSkills,
  }) {
    return _skillsMatchingService.calculateSemanticMatch(
      candidateSkills: candidateSkills,
      requiredSkills: requiredSkills,
      preferredSkills: preferredSkills,
    );
  }
}
