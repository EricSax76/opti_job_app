import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

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
    required String candidateUid,
    required JobOffer offer,
  }) async {
    try {
      final curriculum = await curriculumRepository.fetchCurriculum(
        candidateUid,
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
}
