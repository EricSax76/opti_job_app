import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/home/widgets/widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      backgroundColor: uiBackground,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          uiSpacing24,
          uiSpacing24,
          uiSpacing24,
          uiSpacing32,
        ),
        children: [
          HeroSection(onSeeOffers: () => context.go('/job-offer')),
          const SizedBox(height: uiSpacing32),
          const FeatureSection(),
          const SizedBox(height: uiSpacing32),
          const CandidateBenefitsSection(),
          const SizedBox(height: uiSpacing32),
          const HowItWorksSection(),
          const SizedBox(height: uiSpacing32),
          const CallToActionSection(),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
