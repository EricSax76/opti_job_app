import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/home/containers/onboarding_container.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CoreShell(
      variant: CoreShellVariant.public,
      body: OnboardingContainer(),
    );
  }
}
