import 'dart:math';

import 'package:opti_job_app/modules/applications/models/application.dart';

const Set<String> _initialStatuses = {
  'pending',
  'submitted',
  'reviewing',
  'in_review',
  '',
};

const Set<String> _advancedStatuses = {
  'interviewing',
  'offered',
  'hired',
  'rejected',
  'withdrawn',
};

const List<String> _initialStageHints = [
  'new',
  'screen',
  'criba',
  'triage',
  'presele',
  'applied',
  'aplicad',
];

bool shouldAnonymizeCandidateByStage({
  required String status,
  String? pipelineStageId,
  String? pipelineStageName,
}) {
  final normalizedStatus = status.trim().toLowerCase();
  if (_advancedStatuses.contains(normalizedStatus)) return false;
  if (_initialStatuses.contains(normalizedStatus)) return true;

  final stage = '${pipelineStageId ?? ''} ${pipelineStageName ?? ''}'
      .trim()
      .toLowerCase();
  if (stage.isEmpty) return true;
  return _initialStageHints.any(stage.contains);
}

bool shouldAnonymizeApplication(Application application) {
  return shouldAnonymizeCandidateByStage(
    status: application.status,
    pipelineStageId: application.pipelineStageId,
    pipelineStageName: application.pipelineStageName,
  );
}

String buildAnonymizedCandidateLabel(String candidateUid) {
  final sanitized = candidateUid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (sanitized.isEmpty) return 'Candidato anónimo';
  final suffix = sanitized.substring(0, min(6, sanitized.length)).toUpperCase();
  return 'Candidato #$suffix';
}
