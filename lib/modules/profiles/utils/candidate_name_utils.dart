import 'package:opti_job_app/modules/candidates/models/candidate.dart';

({String firstName, String lastName}) resolveCandidateNames(
    Candidate? candidate) {
  if (candidate == null) {
    return (firstName: '', lastName: '');
  }
  if (candidate.lastName.isNotEmpty) {
    return (firstName: candidate.name, lastName: candidate.lastName);
  }
  return _splitCandidateName(candidate.name);
}

String formatCandidateName(Candidate candidate) {
  final name = candidate.name.trim();
  final lastName = candidate.lastName.trim();
  if (lastName.isEmpty) {
    return name.isNotEmpty ? name : 'Candidato';
  }
  return '$name $lastName'.trim();
}

({String firstName, String lastName}) _splitCandidateName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return (firstName: '', lastName: '');
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return (firstName: parts.first, lastName: '');
  }
  return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
}
