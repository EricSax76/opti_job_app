import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_header.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_section.dart';

class CompanyOffersTab extends StatelessWidget {
  const CompanyOffersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(child: CompanyOffersHeader()),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: CompanyOffersSection(),
        ),
      ],
    );
  }
}
