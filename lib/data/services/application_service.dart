import 'package:opti_job_app/data/repositories/application_repository.dart';

class ApplicationService {
  ApplicationService({
    required ApplicationRepository applicationRepository,
  }) : _applicationRepository = applicationRepository;

  final ApplicationRepository _applicationRepository;

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
}
