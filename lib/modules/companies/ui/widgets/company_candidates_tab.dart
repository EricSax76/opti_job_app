import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_header.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/company_candidates_section.dart';

class CompanyCandidatesTab extends StatelessWidget {
  const CompanyCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            uiSpacing24,
            uiSpacing24,
            uiSpacing24,
            0,
          ),
          sliver: SliverToBoxAdapter(child: CompanyCandidatesHeader()),
        ),
        SliverToBoxAdapter(child: SizedBox(height: uiSpacing12)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            uiSpacing24,
            0,
            uiSpacing24,
            uiSpacing32,
          ),
          sliver: CompanyCandidatesSection(),
        ),
      ],
    );
  }
}
