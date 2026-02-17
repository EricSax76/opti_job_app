import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/home/widgets/onboarding_card.dart';

class OnboardingContainer extends StatelessWidget {
  const OnboardingContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final isCandidate = context.select(
      (CandidateAuthCubit cubit) => cubit.state.isAuthenticated,
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

    return OnboardingCard(
      greeting: l10n.onboardingGreeting(name),
      message: l10n.onboardingMessage,
      confirmLabel: l10n.onboardingConfirmCta,
      onConfirm: () => _handleConfirm(context, isCandidate: isCandidate),
    );
  }

  void _handleConfirm(BuildContext context, {required bool isCandidate}) {
    if (isCandidate) {
      final candidateAuthCubit = context.read<CandidateAuthCubit>();
      candidateAuthCubit.completeOnboarding();
      final uid = candidateAuthCubit.state.candidate?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.go('/candidate/$uid/dashboard');
      } else {
        context.go('/CandidateDashboard');
      }
      return;
    }

    context.read<CompanyAuthCubit>().completeOnboarding();
    context.go('/DashboardCompany');
  }
}
