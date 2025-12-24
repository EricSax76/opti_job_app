import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/home/widgets/widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          HeroSection(onSeeOffers: () => context.go('/job-offer')),
          const SizedBox(height: 40),
          const FeatureSection(),
          const SizedBox(height: 40),
          const CandidateBenefitsSection(),
          const SizedBox(height: 40),
          const HowItWorksSection(),
          const SizedBox(height: 40),
          const CallToActionSection(),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
