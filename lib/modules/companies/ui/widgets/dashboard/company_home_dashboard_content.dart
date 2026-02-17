import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/applicants/ui/widgets/dashboard_candidates_card.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard_home_header.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/dashboard_offers_card.dart';

class CompanyHomeDashboardContent extends StatelessWidget {
  const CompanyHomeDashboardContent({
    super.key,
    required this.onLoadCandidates,
  });

  final VoidCallback onLoadCandidates;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        uiSpacing24,
        uiSpacing24,
        uiSpacing24,
        uiSpacing32,
      ),
      children: [
        const DashboardHomeHeader(),
        const SizedBox(height: uiSpacing16),
        DashboardOffersCard(onLoadCandidates: onLoadCandidates),
        const SizedBox(height: uiSpacing12),
        DashboardCandidatesCard(onLoadCandidates: onLoadCandidates),
      ],
    );
  }
}
