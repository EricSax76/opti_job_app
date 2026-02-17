import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_footer.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/home/widgets/landing_content.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      backgroundColor: uiBackground,
      body: LandingContent(
        onCandidateLogin: () => context.go('/CandidateLogin'),
        onCompanyLogin: () => context.go('/CompanyLogin'),
        onCompanyRegister: () => context.go('/companyregister'),
        onCandidateRegister: () => context.go('/candidateregister'),
        onSeeOffers: () => context.go('/job-offer'),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
