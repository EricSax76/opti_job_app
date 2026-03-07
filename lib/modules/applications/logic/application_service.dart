import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/models/qualified_signature_models.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class ApplicationCreationResult {
  const ApplicationCreationResult({
    required this.applicationId,
    this.warningMessage,
  });

  final String applicationId;
  final String? warningMessage;
}

class ApplicationService {
  final ApplicationRepository _applicationRepository;
  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;
  late final CallableWithFallback _callables;

  ApplicationService({
    required ApplicationRepository applicationRepository,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _applicationRepository = applicationRepository,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _fallbackFunctions = fallbackFunctions ?? FirebaseFunctions.instance {
    _callables = CallableWithFallback(
      functions: _functions,
      fallbackFunctions: _fallbackFunctions,
    );
  }

  Future<ApplicationCreationResult> createApplication({
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

    String? warningMessage;
    if (knockoutResponses != null && knockoutResponses.isNotEmpty) {
      warningMessage = await _evaluateKnockoutSafely(
        applicationId: applicationId,
        responses: knockoutResponses,
      );
    }

    return ApplicationCreationResult(
      applicationId: applicationId,
      warningMessage: warningMessage,
    );
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

    final result = await _callables.call<dynamic>(
      name: 'submitApplication',
      payload: payload,
    );
    final data = result.data;
    if (data is Map) {
      final applicationId = data['applicationId']?.toString().trim();
      if (applicationId != null && applicationId.isNotEmpty) {
        return applicationId;
      }
    }
    throw Exception('submitApplication returned an invalid payload.');
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

  Future<String?> _evaluateKnockoutSafely({
    required String applicationId,
    required Map<String, dynamic> responses,
  }) async {
    final payload = <String, dynamic>{
      'applicationId': applicationId,
      'responses': responses,
    };

    try {
      final result = await _functions
          .httpsCallable('evaluateKnockoutQuestions')
          .call(payload);
      return _resolveKnockoutWarning(result.data);
    } on FirebaseFunctionsException catch (error) {
      if (_isRetriableKnockoutError(error.code)) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        try {
          final retryResult = await _functions
              .httpsCallable('evaluateKnockoutQuestions')
              .call(payload);
          return _resolveKnockoutWarning(retryResult.data);
        } on FirebaseFunctionsException {
          // Continuamos con fallback para no perder señal operativa.
        } catch (_) {
          // Continuamos con fallback para no perder señal operativa.
        }
      }

      try {
        final fallbackResult = await _fallbackFunctions
            .httpsCallable('evaluateKnockoutQuestions')
            .call(payload);
        return _resolveKnockoutWarning(fallbackResult.data);
      } on FirebaseFunctionsException catch (fallbackError) {
        return _defaultKnockoutWarning(
          errorCode: fallbackError.code,
          responseData: fallbackError.details,
        );
      } catch (_) {
        return _defaultKnockoutWarning(errorCode: error.code);
      }
    } catch (_) {
      try {
        final fallbackResult = await _fallbackFunctions
            .httpsCallable('evaluateKnockoutQuestions')
            .call(payload);
        return _resolveKnockoutWarning(fallbackResult.data);
      } on FirebaseFunctionsException catch (error) {
        return _defaultKnockoutWarning(
          errorCode: error.code,
          responseData: error.details,
        );
      } catch (_) {
        return _defaultKnockoutWarning();
      }
    }
  }

  bool _isRetriableKnockoutError(String code) {
    switch (code) {
      case 'aborted':
      case 'deadline-exceeded':
      case 'internal':
      case 'resource-exhausted':
      case 'unavailable':
      case 'unknown':
        return true;
      default:
        return false;
    }
  }

  String? _resolveKnockoutWarning(dynamic responseData) {
    if (responseData is! Map) return null;
    final data = Map<String, dynamic>.from(responseData);
    final consentRequired = data['consentRequired'] == true;
    if (consentRequired) {
      return 'Tu postulación fue enviada, pero falta consentimiento de IA para completar la evaluación knockout.';
    }

    final success = data['success'];
    if (success is bool && success) {
      return null;
    }

    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return 'Tu postulación fue enviada, pero la evaluación knockout quedó pendiente: $message';
    }
    return _defaultKnockoutWarning();
  }

  String _defaultKnockoutWarning({String? errorCode, dynamic responseData}) {
    final normalizedCode = errorCode?.trim().toLowerCase() ?? '';
    if (normalizedCode == 'permission-denied') {
      return 'Tu postulación fue enviada, pero la evaluación knockout no pudo ejecutarse por permisos.';
    }
    if (normalizedCode == 'failed-precondition') {
      return 'Tu postulación fue enviada, pero la evaluación knockout requiere completar precondiciones pendientes.';
    }

    if (responseData is Map) {
      final details = responseData['message']?.toString().trim();
      if (details != null && details.isNotEmpty) {
        return 'Tu postulación fue enviada, pero la evaluación knockout quedó pendiente: $details';
      }
    }

    return 'Tu postulación fue enviada, pero la evaluación knockout quedó pendiente por un error temporal.';
  }

  Future<QualifiedSignatureStartResult> startQualifiedOfferSignature({
    required String applicationId,
    String provider = 'qualified_trust_service_eidas',
  }) async {
    final data = await _callCallableWithFallback(
      name: 'startQualifiedOfferSignature',
      payload: {
        'applicationId': applicationId.trim(),
        'provider': provider.trim().isEmpty
            ? 'qualified_trust_service_eidas'
            : provider.trim(),
      },
    );
    return QualifiedSignatureStartResult.fromJson(data);
  }

  Future<QualifiedSignatureConfirmResult> confirmQualifiedOfferSignature({
    required String requestId,
    required String otpCode,
    required String certificateFingerprint,
    required String providerReference,
  }) async {
    final data = await _callCallableWithFallback(
      name: 'confirmQualifiedOfferSignature',
      payload: {
        'requestId': requestId.trim(),
        'otpCode': otpCode.trim(),
        'certificateFingerprint': certificateFingerprint.trim(),
        'providerReference': providerReference.trim(),
      },
    );
    return QualifiedSignatureConfirmResult.fromJson(data);
  }

  Future<QualifiedSignatureStatusResult> getQualifiedOfferSignatureStatus({
    required String applicationId,
  }) async {
    final data = await _callCallableWithFallback(
      name: 'getQualifiedOfferSignatureStatus',
      payload: {'applicationId': applicationId.trim()},
    );
    return QualifiedSignatureStatusResult.fromJson(data);
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String name,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    return _callables.callMap(name: name, payload: payload);
  }
}
