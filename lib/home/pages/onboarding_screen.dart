import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/home/containers/onboarding_container.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: const OnboardingContainer(),
    );
  }
}
