import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/companies/logic/company_home_dashboard_controller.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_home_dashboard_content.dart';

class CompanyHomeDashboard extends StatelessWidget {
  const CompanyHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return CompanyHomeDashboardContent(
      onLoadCandidates: () =>
          CompanyHomeDashboardController.loadApplicantsForAllOffers(context),
    );
  }
}
