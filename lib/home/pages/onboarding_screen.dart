import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubits/auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCandidate = context.select(
      (AuthCubit cubit) => cubit.state.isCandidate,
    );
    final candidateName = context.select(
      (ProfileCubit cubit) => cubit.state.candidate?.name,
    );
    final companyName = context.select(
      (ProfileCubit cubit) => cubit.state.company?.name,
    );
    final l10n = AppLocalizations.of(context)!;

    final name = isCandidate
        ? candidateName ?? l10n.onboardingDefaultCandidateName
        : companyName ?? l10n.onboardingDefaultCompanyName;

    return Scaffold(
      appBar: const AppNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(uiSpacing24),
            child: Padding(
              padding: const EdgeInsets.all(uiSpacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingGreeting(name),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: uiSpacing12),
                  Text(
                    l10n.onboardingMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: uiSpacing24),
                  FilledButton.icon(
                    onPressed: () {
                      if (isCandidate) {
                        context.read<CandidateAuthCubit>().completeOnboarding();
                        final uid = context
                            .read<CandidateAuthCubit>()
                            .state
                            .candidate
                            ?.uid;
                        if (uid != null && uid.isNotEmpty) {
                          context.go('/candidate/$uid/dashboard');
                        } else {
                          context.go('/CandidateDashboard');
                        }
                      } else {
                        context.read<CompanyAuthCubit>().completeOnboarding();
                        context.go('/DashboardCompany');
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.onboardingConfirmCta),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
