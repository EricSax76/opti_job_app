import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_header.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_section.dart';

class CompanyCandidatesTab extends StatelessWidget {
  const CompanyCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(child: CompanyCandidatesHeader()),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: CompanyCandidatesSection(),
        ),
      ],
    );
  }
}
