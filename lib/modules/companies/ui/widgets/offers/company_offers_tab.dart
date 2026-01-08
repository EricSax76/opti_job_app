import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_dashboard_widgets.dart';

class CompanyOffersTab extends StatelessWidget {
  const CompanyOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: const [
        CompanyOffersHeader(),
        SizedBox(height: 12),
        CompanyOffersRepositorySection(),
      ],
    );
  }
}
