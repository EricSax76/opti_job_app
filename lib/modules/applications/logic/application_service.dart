import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class ApplicationService {
  final ApplicationRepository _applicationRepository;
  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;

  ApplicationService({
    required ApplicationRepository applicationRepository,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _applicationRepository = applicationRepository,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _fallbackFunctions = fallbackFunctions ?? FirebaseFunctions.instance;

  Future<String> createApplication({
    required JobOffer jobOffer,
    required Candidate candidate,
    int? candidateProfileId,
    Map<String, dynamic>? knockoutResponses,
    String sourceChannel = 'platform',
  }) async {
    final exists = await _applicationRepository.applicationExists(
      jobOfferId: jobOffer.id,
      candidateUid: candidate.uid,
    );

    if (exists) {
      throw Exception('Application already exists');
    }

    final applicationId = await _createApplicationWithServerAck(
      jobOffer: jobOffer,
      candidate: candidate,
      candidateProfileId: candidateProfileId,
      knockoutResponses: knockoutResponses,
      sourceChannel: sourceChannel,
    );

    if (knockoutResponses != null && knockoutResponses.isNotEmpty) {
      await _evaluateKnockoutSafely(
        applicationId: applicationId,
        responses: knockoutResponses,
      );
    }

    return applicationId;
  }

  Future<String> _createApplicationWithServerAck({
    required JobOffer jobOffer,
    required Candidate candidate,
    int? candidateProfileId,
    Map<String, dynamic>? knockoutResponses,
    required String sourceChannel,
  }) async {
    final payload = <String, dynamic>{
      'jobOfferId': jobOffer.id,
      'curriculumId': 'main',
      'sourceChannel': sourceChannel,
    };

    try {
      final result = await _functions
          .httpsCallable('submitApplication')
          .call(payload);
      final data = result.data;
      if (data is Map) {
        final applicationId = data['applicationId']?.toString().trim();
        if (applicationId != null && applicationId.isNotEmpty) {
          return applicationId;
        }
      }
      throw Exception('submitApplication returned an invalid payload.');
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') {
        rethrow;
      }
      final fallbackResult = await _fallbackFunctions
          .httpsCallable('submitApplication')
          .call(payload);
      final data = fallbackResult.data;
      if (data is Map) {
        final applicationId = data['applicationId']?.toString().trim();
        if (applicationId != null && applicationId.isNotEmpty) {
          return applicationId;
        }
      }
      throw Exception(
        'submitApplication fallback returned an invalid payload.',
      );
    }
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

  Future<void> _evaluateKnockoutSafely({
    required String applicationId,
    required Map<String, dynamic> responses,
  }) async {
    final payload = <String, dynamic>{
      'applicationId': applicationId,
      'responses': responses,
    };

    try {
      await _functions.httpsCallable('evaluateKnockoutQuestions').call(payload);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found') return;
      try {
        await _fallbackFunctions
            .httpsCallable('evaluateKnockoutQuestions')
            .call(payload);
      } on FirebaseFunctionsException {
        // No bloqueamos la postulación si falla la evaluación automática.
      }
    } catch (_) {
      // No bloqueamos la postulación si falla la evaluación automática.
    }
  }
}
