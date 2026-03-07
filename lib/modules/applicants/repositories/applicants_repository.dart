import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/models/ai_decision_review.dart';
import 'package:opti_job_app/modules/applicants/models/applicant_review_profile.dart';

abstract class ApplicantsRepository {
  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  });

  Future<Map<String, List<Application>>> getApplicationsForOffers({
    required Iterable<String> jobOfferIds,
    required String companyUid,
  });

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  });

  Future<AiDecisionReview> getAiDecisionReview({
    required String applicationId,
    int limit = 20,
  });

  Future<AiDecisionOverrideResult> overrideAiDecision({
    required String applicationId,
    required String reason,
    double? overrideScore,
    double? originalAiScore,
  });

  Future<void> runAiVectorMatch({required String applicationId, int limit = 8});

  Future<void> runAiSkillMatch({
    required String applicationId,
    required String jobOfferId,
  });

  Future<ApplicantReviewProfile> getApplicantProfileForReview({
    String? applicationId,
    required String candidateUid,
    required String jobOfferId,
  });
}
