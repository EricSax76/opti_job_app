import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/home/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/home/widgets/candidate_onboarding_flow.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
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

    if (isCandidate) {
      return BlocProvider(
        create: (_) => CandidateOnboardingCubit(),
        child: CandidateOnboardingFlow(
          candidateName: name,
          onCompleted: (state) => _handleConfirm(
            context,
            isCandidate: true,
            onboardingState: state,
          ),
        ),
      );
    }

    return OnboardingCard(
      greeting: l10n.onboardingGreeting(name),
      message: l10n.onboardingMessage,
      confirmLabel: l10n.onboardingConfirmCta,
      onConfirm: () => _handleConfirm(context, isCandidate: false),
    );
  }

  Future<void> _handleConfirm(
    BuildContext context, {
    required bool isCandidate,
    CandidateOnboardingState? onboardingState,
  }) async {
    if (isCandidate) {
      final candidateAuthCubit = context.read<CandidateAuthCubit>();
      final uid = candidateAuthCubit.state.candidate?.uid;
      final resolvedOnboardingState =
          onboardingState ?? context.read<CandidateOnboardingCubit>().state;
      if (uid != null && uid.isNotEmpty) {
        final onboardingProfile = CandidateOnboardingProfile(
          targetRole: resolvedOnboardingState.targetRole.trim(),
          preferredLocation: resolvedOnboardingState.preferredLocation.trim(),
          preferredModality: resolvedOnboardingState.preferredModality.trim(),
          preferredSeniority: resolvedOnboardingState.preferredSeniority.trim(),
          workStyleSkipped: resolvedOnboardingState.workStyleSkipped,
          startOfDayPreference: _normalizeOptional(
            resolvedOnboardingState.startOfDayPreference,
          ),
          feedbackPreference: _normalizeOptional(
            resolvedOnboardingState.feedbackPreference,
          ),
          structurePreference: _normalizeOptional(
            resolvedOnboardingState.structurePreference,
          ),
          taskPacePreference: _normalizeOptional(
            resolvedOnboardingState.taskPacePreference,
          ),
        );
        final repository = context.read<ProfileRepository>();
        unawaited(
          _persistCandidateOnboardingProfile(
            repository: repository,
            uid: uid,
            onboardingProfile: onboardingProfile,
          ),
        );
      }
      if (!context.mounted) return;
      candidateAuthCubit.completeOnboarding();
      if (uid != null && uid.isNotEmpty) {
        context.go('/candidate/$uid/dashboard');
      } else {
        context.go('/CandidateDashboard');
      }
      return;
    }

    final companyAuthCubit = context.read<CompanyAuthCubit>();
    companyAuthCubit.completeOnboarding();
    final uid = companyAuthCubit.state.company?.uid;
    if (uid != null && uid.isNotEmpty) {
      context.go('/company/$uid/dashboard');
      return;
    }
    context.go('/DashboardCompany');
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<void> _persistCandidateOnboardingProfile({
    required ProfileRepository repository,
    required String uid,
    required CandidateOnboardingProfile onboardingProfile,
  }) async {
    try {
      await repository
          .saveCandidateOnboardingProfile(
            uid: uid,
            onboardingProfile: onboardingProfile,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Non-blocking by design: onboarding navigation should not hang on I/O.
    }
  }
}
