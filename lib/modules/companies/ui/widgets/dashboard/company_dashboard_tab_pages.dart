import 'package:flutter/material.dart';

import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_home_dashboard.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_candidates_tab.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_interviews_tab.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_offer_creation_tab.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_tab.dart';

List<Widget> companyDashboardTabPages() {
  return const [
    CompanyHomeDashboard(),
    CompanyOfferCreationTab(),
    CompanyOffersTab(),
    CompanyCandidatesTab(),
    if (FeatureFlags.interviews) CompanyInterviewsTab(),
  ];
}
