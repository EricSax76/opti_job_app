import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

abstract class JobOfferMatchOutcome {
  const JobOfferMatchOutcome();
}

class JobOfferMatchSuccess extends JobOfferMatchOutcome {
  const JobOfferMatchSuccess(this.result);

  final AiMatchResult result;
}

class JobOfferMatchFailure extends JobOfferMatchOutcome {
  const JobOfferMatchFailure(this.message);

  final String message;
}

class JobOfferMatchLogic {
  const JobOfferMatchLogic._();

  static const String locale = 'es-ES';

  static Future<JobOfferMatchOutcome> computeMatch({
    required CurriculumRepository curriculumRepository,
    required AiRepository aiRepository,
    required ProfileRepository profileRepository,
    required String candidateUid,
    required JobOffer offer,
  }) async {
    try {
      final baseCurriculum = await curriculumRepository.fetchCurriculum(
        candidateUid,
      );
      CandidateOnboardingProfile? onboardingProfile;
      try {
        final candidateProfile = await profileRepository.fetchCandidateProfile(
          candidateUid,
        );
        onboardingProfile = candidateProfile.onboardingProfile;
      } catch (_) {
        onboardingProfile = null;
      }
      final curriculum = _enrichCurriculumWithOnboarding(
        curriculum: baseCurriculum,
        profile: onboardingProfile,
      );
      final result = await aiRepository.matchOfferCandidate(
        curriculum: curriculum,
        offer: offer,
        locale: locale,
      );
      return JobOfferMatchSuccess(result);
    } on AiConfigurationException catch (error) {
      return JobOfferMatchFailure(error.message);
    } on AiRequestException catch (error) {
      return JobOfferMatchFailure(error.message);
    } catch (_) {
      return const JobOfferMatchFailure('No se pudo calcular el match.');
    }
  }

  static Curriculum _enrichCurriculumWithOnboarding({
    required Curriculum curriculum,
    required CandidateOnboardingProfile? profile,
  }) {
    if (profile == null) return curriculum;

    final contextLines = <String>[
      'Rol objetivo: ${profile.targetRole}',
      'Modalidad preferida: ${profile.preferredModality}',
      'Ubicación preferida: ${profile.preferredLocation}',
      'Seniority preferido: ${profile.preferredSeniority}',
      if (_hasText(profile.startOfDayPreference))
        'Inicio de jornada preferido: ${profile.startOfDayPreference}',
      if (_hasText(profile.feedbackPreference))
        'Feedback preferido: ${profile.feedbackPreference}',
      if (_hasText(profile.structurePreference))
        'Estructura de trabajo preferida: ${profile.structurePreference}',
      if (_hasText(profile.taskPacePreference))
        'Ritmo de trabajo preferido: ${profile.taskPacePreference}',
    ];

    final currentSummary = curriculum.summary.trim();
    final onboardingContext = contextLines.join(' | ').trim();
    final mergedSummary = [
      if (currentSummary.isNotEmpty) currentSummary,
      if (onboardingContext.isNotEmpty) 'Preferencias: $onboardingContext',
    ].join('\n\n');

    final mergedHeadline = curriculum.headline.trim().isNotEmpty
        ? curriculum.headline
        : profile.targetRole;
    final mergedLocation = curriculum.location.trim().isNotEmpty
        ? curriculum.location
        : profile.preferredLocation;

    final mergedSkills = <String>{
      ...curriculum.skills.map((skill) => skill.trim()).where(_hasText),
      'Modalidad preferida: ${profile.preferredModality}',
      'Seniority objetivo: ${profile.preferredSeniority}',
    }.toList(growable: false);

    return curriculum.copyWith(
      headline: mergedHeadline,
      summary: mergedSummary,
      location: mergedLocation,
      skills: mergedSkills,
    );
  }

  static bool _hasText(String? value) {
    final trimmed = value?.trim();
    return trimmed != null && trimmed.isNotEmpty;
  }
}
