import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/interviews/models/interview.dart';

class InterviewListTileTitle extends StatelessWidget {
  const InterviewListTileTitle({
    super.key,
    required this.interview,
    required this.isCompany,
  });

  final Interview interview;
  final bool isCompany;

  @override
  Widget build(BuildContext context) {
    final title = isCompany
        ? 'Candidato (ID: ${_shortUid(interview.candidateUid)})'
        : 'Empresa (ID: ${_shortUid(interview.companyUid)})';

    return Text(title, style: const TextStyle(fontWeight: FontWeight.w600));
  }

  String _shortUid(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return 'N/A';
    if (trimmed.length <= 5) return trimmed;
    return '${trimmed.substring(0, 5)}...';
  }
}
