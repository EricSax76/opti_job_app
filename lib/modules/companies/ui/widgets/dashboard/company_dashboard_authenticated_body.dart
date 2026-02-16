import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_nav_bar.dart';

class CompanyDashboardAuthenticatedBody extends StatelessWidget {
  const CompanyDashboardAuthenticatedBody({
    super.key,
    required this.tabController,
    required this.tabPages,
  });

  final TabController tabController;
  final List<Widget> tabPages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CompanyDashboardNavBar(controller: tabController),
        Expanded(
          child: TabBarView(controller: tabController, children: tabPages),
        ),
      ],
    );
  }
}
