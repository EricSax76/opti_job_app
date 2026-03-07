import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/applicants/models/ai_decision_review.dart';
import 'package:opti_job_app/modules/applicants/models/applicant_review_profile.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class FirebaseApplicantsRepository implements ApplicantsRepository {
  FirebaseApplicantsRepository({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _firestore = firestore,
       _callables = CallableWithFallback(
         functions:
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
         fallbackFunctions: fallbackFunctions ?? FirebaseFunctions.instance,
       );

  final FirebaseFirestore _firestore;
  final CallableWithFallback _callables;

  /// Fetches applications for a single offer via the blind-review callable.
  ///
  /// The Cloud Function [getApplicationsForReview] projects fields based on
  /// each application's pipeline stage (LGPD blind review), so the frontend
  /// never receives PII that should be hidden at the current stage.
  @override
  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  }) async {
    final normalizedOfferId = jobOfferId.trim();
    if (normalizedOfferId.isEmpty) return const [];

    final data = await _callables.callMap(
      name: 'getApplicationsForReview',
      payload: {'jobOfferId': normalizedOfferId},
    );
    final rawList = (data['applications'] as List<dynamic>?) ?? [];

    final applications = rawList
        .cast<Map<String, dynamic>>()
        .map(
          (json) =>
              Application.fromJson(json, id: json['applicationId'] as String?),
        )
        .toList();

    applications.sort(_sortByMostRecent);
    return applications;
  }

  /// Fetches applications for multiple offers.
  ///
  /// Calls the blind-review callable once per offer. Each call returns only
  /// the fields the recruiter is allowed to see at that pipeline stage.
  @override
  Future<Map<String, List<Application>>> getApplicationsForOffers({
    required Iterable<String> jobOfferIds,
    required String companyUid,
  }) async {
    final normalizedOfferIds = jobOfferIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedOfferIds.isEmpty) return const {};

    final applicationsByOffer = <String, List<Application>>{
      for (final offerId in normalizedOfferIds) offerId: <Application>[],
    };

    // Fire all callable requests in parallel
    final futures = <String, Future<Map<String, dynamic>>>{
      for (final offerId in normalizedOfferIds)
        offerId: _callables.callMap(
          name: 'getApplicationsForReview',
          payload: {'jobOfferId': offerId},
        ),
    };

    for (final entry in futures.entries) {
      try {
        final payload = await entry.value;
        final rawList = (payload['applications'] as List<dynamic>?) ?? [];

        final apps = rawList
            .cast<Map<String, dynamic>>()
            .map(
              (json) => Application.fromJson(
                json,
                id: json['applicationId'] as String?,
              ),
            )
            .toList();

        apps.sort(_sortByMostRecent);
        applicationsByOffer[entry.key] = apps;
      } catch (_) {
        // Individual offer failure — keep empty list for that offer.
        applicationsByOffer[entry.key] = const [];
      }
    }

    return applicationsByOffer;
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<AiDecisionReview> getAiDecisionReview({
    required String applicationId,
    int limit = 20,
  }) async {
    final result = await _callWithRegionFallback(
      'getAiDecisionReview',
      <String, dynamic>{'applicationId': applicationId, 'limit': limit},
    );
    final data = CallableWithFallback.asMap(result.data);
    return AiDecisionReview.fromJson(data);
  }

  @override
  Future<AiDecisionOverrideResult> overrideAiDecision({
    required String applicationId,
    required String reason,
    double? overrideScore,
    double? originalAiScore,
  }) async {
    final payload = <String, dynamic>{
      'applicationId': applicationId,
      'reason': reason,
      ...?overrideScore == null
          ? null
          : <String, dynamic>{'overrideScore': overrideScore},
      ...?originalAiScore == null
          ? null
          : <String, dynamic>{'originalAiScore': originalAiScore},
    };
    final result = await _callWithRegionFallback('overrideAiDecision', payload);
    final data = CallableWithFallback.asMap(result.data);
    return AiDecisionOverrideResult.fromJson(data);
  }

  @override
  Future<void> runAiVectorMatch({
    required String applicationId,
    int limit = 8,
  }) async {
    await _callWithRegionFallback('matchCandidateVector', <String, dynamic>{
      'applicationId': applicationId,
      'limit': limit,
    });
  }

  @override
  Future<void> runAiSkillMatch({
    required String applicationId,
    required String jobOfferId,
  }) async {
    await _callWithRegionFallback('matchCandidateWithSkills', <String, dynamic>{
      'applicationId': applicationId,
      'jobOfferId': jobOfferId,
    });
  }

  @override
  Future<ApplicantReviewProfile> getApplicantProfileForReview({
    String? applicationId,
    required String candidateUid,
    required String jobOfferId,
  }) async {
    final normalizedApplicationId = applicationId?.trim() ?? '';
    final payload = await _callables.callMap(
      name: 'getApplicantProfileForReview',
      payload: {
        if (normalizedApplicationId.isNotEmpty)
          'applicationId': normalizedApplicationId,
        'candidateUid': candidateUid.trim(),
        'jobOfferId': jobOfferId.trim(),
      },
    );

    final candidateJson = CallableWithFallback.asMap(payload['candidate']);
    final curriculumJson = CallableWithFallback.asMap(payload['curriculum']);

    return ApplicantReviewProfile(
      candidate: Candidate.fromJson(candidateJson),
      curriculum: Curriculum.fromJson(curriculumJson),
      revealLevel: (payload['revealLevel'] as String?)?.trim() ?? 'blind',
      hasVideoCurriculum: payload['hasVideoCurriculum'] as bool? ?? false,
      canViewVideoCurriculum:
          payload['canViewVideoCurriculum'] as bool? ?? false,
    );
  }

  Future<HttpsCallableResult<dynamic>> _callWithRegionFallback(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    return _callables.call<dynamic>(name: functionName, payload: payload);
  }

  static int _sortByMostRecent(Application a, Application b) {
    final aDate = a.updatedAt ?? a.createdAt;
    final bDate = b.updatedAt ?? b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}
