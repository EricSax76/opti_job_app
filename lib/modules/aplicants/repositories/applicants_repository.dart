import 'package:opti_job_app/modules/aplications/models/application.dart';

abstract class ApplicantsRepository {
  Future<List<Application>> getApplicationsForOffer({
    required int jobOfferId,
    required String companyUid,
  });

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  });
}
