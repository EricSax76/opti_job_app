import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';

class CandidateOnboardingFilterLogic {
  const CandidateOnboardingFilterLogic._();

  static JobOfferFilters? buildInitialFilters(Candidate? candidate) {
    final profile = candidate?.onboardingProfile;
    if (profile == null) return null;

    final query = _composeSearchQuery(
      role: profile.targetRole,
      seniority: profile.preferredSeniority,
    );
    final location = _normalize(profile.preferredLocation);
    final jobType = _mapModalityToJobType(profile.preferredModality);

    if (query == null && location == null && jobType == null) return null;

    return JobOfferFilters(
      searchQuery: query,
      location: location,
      jobType: jobType,
    );
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _composeSearchQuery({
    required String role,
    required String seniority,
  }) {
    final normalizedRole = _normalize(role);
    final normalizedSeniority = _normalize(seniority);
    if (normalizedRole == null && normalizedSeniority == null) return null;
    final roleParts = normalizedRole == null ? null : <String>[normalizedRole];
    final seniorityParts = normalizedSeniority == null
        ? null
        : <String>[normalizedSeniority];
    return [...?roleParts, ...?seniorityParts].join(' ');
  }

  static String? _mapModalityToJobType(String? modality) {
    final normalized = _normalize(modality)?.toLowerCase();
    if (normalized == null) return null;
    switch (normalized) {
      case 'remoto':
      case 'solo remoto':
      case 'teletrabajo':
        return 'Solo teletrabajo';
      case 'hibrido':
      case 'híbrido':
        return 'Híbrido';
      case 'presencial':
        return 'Presencial';
      default:
        return null;
    }
  }
}
