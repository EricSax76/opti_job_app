import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class ApplicationService {
  final ApplicationRepository _applicationRepository;

  ApplicationService({required ApplicationRepository applicationRepository})
    : _applicationRepository = applicationRepository;

  Future<void> createApplication({
    required JobOffer jobOffer,
    required Candidate candidate,
    int? candidateProfileId,
  }) async {
    final exists = await _applicationRepository.applicationExists(
      jobOfferId: jobOffer.id,
      candidateUid: candidate.uid,
    );

    if (exists) {
      throw Exception('Application already exists');
    }

    await _applicationRepository.createApplication(
      jobOffer: jobOffer,
      candidate: candidate,
      candidateProfileId: candidateProfileId ?? candidate.id,
    );
  }

  Future<List<CandidateApplicationEntry>> getApplicationEntriesForCandidate(
    String candidateUid,
  ) {
    return _applicationRepository.getApplicationsForCandidate(
      candidateUid: candidateUid,
    );
  }

  Future<Application?> getApplicationForCandidateOffer({
    required String jobOfferId,
    required String candidateUid,
  }) {
    return _applicationRepository.getApplicationForCandidateOffer(
      jobOfferId: jobOfferId,
      candidateUid: candidateUid,
    );
  }

  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  }) {
    return _applicationRepository.getApplicationsForOffer(
      jobOfferId: jobOfferId,
      companyUid: companyUid,
    );
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) {
    return _applicationRepository.updateApplicationStatus(
      applicationId: applicationId,
      status: status,
    );
  }
}
