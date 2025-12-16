import 'package:opti_job_app/data/repositories/application_repository.dart';
import 'package:opti_job_app/data/models/job_offer.dart';

class ApplicationService {
  final ApplicationRepository _applicationRepository;

  ApplicationService({required ApplicationRepository applicationRepository})
    : _applicationRepository = applicationRepository;

  Future<void> createApplication({
    required int jobOfferId,
    required int candidateId,
  }) async {
    final exists = await _applicationRepository.applicationExists(
      jobOfferId: jobOfferId,
      candidateId: candidateId,
    );

    if (exists) {
      throw Exception('Application already exists');
    }

    await _applicationRepository.createApplication(
      jobOfferId: jobOfferId,
      candidateId: candidateId,
    );
  }

  Future<List<JobOffer>> getApplicationsForCandidate(int candidateId) {
    return _applicationRepository.getApplicationsForCandidate(
      candidateId: candidateId,
    );
  }
}
