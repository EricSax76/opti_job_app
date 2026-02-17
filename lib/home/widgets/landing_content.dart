import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/home/widgets/call_to_action_section.dart';
import 'package:opti_job_app/home/widgets/candidate_benefits_section.dart';
import 'package:opti_job_app/home/widgets/feature_section.dart';
import 'package:opti_job_app/home/widgets/hero_section.dart';
import 'package:opti_job_app/home/widgets/how_it_works_section.dart';

class LandingContent extends StatelessWidget {
  const LandingContent({
    super.key,
    required this.onCandidateLogin,
    required this.onCompanyLogin,
    required this.onCompanyRegister,
    required this.onCandidateRegister,
    required this.onSeeOffers,
  });

  final VoidCallback onCandidateLogin;
  final VoidCallback onCompanyLogin;
  final VoidCallback onCompanyRegister;
  final VoidCallback onCandidateRegister;
  final VoidCallback onSeeOffers;

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
        HeroSection(
          onCandidateLogin: onCandidateLogin,
          onCompanyLogin: onCompanyLogin,
          onSeeOffers: onSeeOffers,
        ),
        const SizedBox(height: uiSpacing32),
        const FeatureSection(),
        const SizedBox(height: uiSpacing32),
        const CandidateBenefitsSection(),
        const SizedBox(height: uiSpacing32),
        const HowItWorksSection(),
        const SizedBox(height: uiSpacing32),
        CallToActionSection(
          onCompanyRegister: onCompanyRegister,
          onCandidateRegister: onCandidateRegister,
          onSeeOffers: onSeeOffers,
        ),
      ],
    );
  }
}
