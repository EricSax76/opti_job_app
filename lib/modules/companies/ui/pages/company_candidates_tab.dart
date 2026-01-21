import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/aplicants/ui/widgets/company_candidates_header.dart';
import 'package:opti_job_app/modules/aplicants/ui/widgets/company_candidates_section.dart';

class CompanyCandidatesTab extends StatelessWidget {
  const CompanyCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: const [
        CompanyCandidatesHeader(),
        SizedBox(height: 12),
        CompanyCandidatesSection(),
      ],
    );
  }
}
