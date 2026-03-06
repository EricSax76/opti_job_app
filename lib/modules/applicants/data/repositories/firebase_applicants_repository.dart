import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';

class FirebaseApplicantsRepository implements ApplicantsRepository {
  FirebaseApplicantsRepository({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

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

    final callable = _functions.httpsCallable('getApplicationsForReview');
    final result = await callable.call<Map<String, dynamic>>({
      'jobOfferId': normalizedOfferId,
    });

    final data = result.data;
    final rawList = (data['applications'] as List<dynamic>?) ?? [];

    final applications = rawList
        .cast<Map<String, dynamic>>()
        .map((json) => Application.fromJson(
              json,
              id: json['applicationId'] as String?,
            ))
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
    final futures = <String, Future<HttpsCallableResult<Map<String, dynamic>>>>{
      for (final offerId in normalizedOfferIds)
        offerId: _functions
            .httpsCallable('getApplicationsForReview')
            .call<Map<String, dynamic>>({'jobOfferId': offerId}),
    };

    for (final entry in futures.entries) {
      try {
        final result = await entry.value;
        final rawList =
            (result.data['applications'] as List<dynamic>?) ?? [];

        final apps = rawList
            .cast<Map<String, dynamic>>()
            .map((json) => Application.fromJson(
                  json,
                  id: json['applicationId'] as String?,
                ))
            .toList();

        apps.sort(_sortByMostRecent);
        applicationsByOffer[entry.key] = apps;
      } catch (_) {
        // Individual offer failure — keep empty list for that offer
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

  static int _sortByMostRecent(Application a, Application b) {
    final aDate = a.updatedAt ?? a.createdAt;
    final bDate = b.updatedAt ?? b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}
