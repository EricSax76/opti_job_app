import 'package:opti_job_app/modules/applications/models/application.dart';

/// Whether this application's candidate identity is currently hidden.
///
/// The backend callable [getApplicationsForReview] already projects fields
/// based on the pipeline stage (LGPD blind review). If [candidateName] is
/// `null`, the candidate is still anonymized at this stage.
///
/// This replaces the previous heuristic that guessed anonymization from
/// status strings and stage name hints.
bool shouldAnonymizeApplication(Application application) {
  return application.candidateName == null;
}

/// Convenience wrapper matching the old API surface.
bool shouldAnonymizeCandidateByStage({
  required String status,
  String? pipelineStageId,
  String? pipelineStageName,
  String? candidateName,
}) {
  // With the callable-based blind review, the authoritative signal is
  // whether the backend returned a name. If called without a name
  // parameter (legacy path), fall back to identityRevealed semantics.
  return candidateName == null;
}

/// Display label for an anonymized candidate.
///
/// Prefers the server-generated [anonymizedLabel] ("Candidato #ABC123").
/// Falls back to a local derivation from [candidateUid] only when the
/// server label is unavailable (e.g. candidate's own view).
String buildAnonymizedCandidateLabel(
  String candidateUid, {
  String? anonymizedLabel,
}) {
  if (anonymizedLabel != null && anonymizedLabel.isNotEmpty) {
    return anonymizedLabel;
  }
  final sanitized = candidateUid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (sanitized.isEmpty) return 'Candidato anónimo';
  final suffix = sanitized
      .substring(0, sanitized.length < 6 ? sanitized.length : 6)
      .toUpperCase();
  return 'Candidato #$suffix';
}
