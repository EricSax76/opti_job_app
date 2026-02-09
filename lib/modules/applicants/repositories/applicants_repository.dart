import 'package:opti_job_app/modules/applications/models/application.dart';

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
}
