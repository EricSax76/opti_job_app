import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/logic/candidate_onboarding_step_view_model_factory.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_card_base_layout.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class OnboardingContainer extends StatelessWidget {
  const OnboardingContainer({super.key});

  static const CandidateOnboardingStepViewModelFactory _viewModelFactory =
      CandidateOnboardingStepViewModelFactory();
  static const double _candidateOnboardingCardMaxWidth =
      uiBreakpointMobile + uiSpacing20;
  static const double _defaultOnboardingCardMaxWidth =
      uiBreakpointMobile - uiSpacing48 - uiSpacing32;

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
        child: BlocConsumer<CandidateOnboardingCubit, CandidateOnboardingState>(
          listenWhen: (previous, current) =>
              previous.submissionStatus != current.submissionStatus,
          listener: (context, state) {
            if (state.submissionStatus ==
                CandidateOnboardingSubmissionStatus.completed) {
              _handleConfirm(
                context,
                isCandidate: true,
                onboardingState: state,
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<CandidateOnboardingCubit>();
            final stepViewModel = _viewModelFactory.build(
              state: state,
              cubit: cubit,
              candidateName: name,
              l10n: l10n,
            );

            return _buildOnboardingCard(
              title: stepViewModel.title,
              message: stepViewModel.message,
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(state.currentStep),
                  child: stepViewModel.body,
                ),
              ),
              primaryLabel: stepViewModel.primaryLabel,
              primaryIcon: stepViewModel.primaryIcon,
              onPrimaryPressed: stepViewModel.onPrimaryPressed,
              primaryEnabled: stepViewModel.primaryEnabled,
              secondaryLabel: stepViewModel.secondaryLabel,
              onSecondaryPressed: stepViewModel.onSecondaryPressed,
              tertiaryLabel: stepViewModel.tertiaryLabel,
              onTertiaryPressed: stepViewModel.onTertiaryPressed,
              showHeaderMedallion: false,
              stepIndex: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabel: l10n.onboardingCandidateStepProgressLabel(
                state.currentStepIndex,
                state.totalSteps,
              ),
              maxContentWidth: _candidateOnboardingCardMaxWidth,
            );
          },
        ),
      );
    }

    return _buildOnboardingCard(
      title: l10n.onboardingGreeting(name),
      message: l10n.onboardingMessage,
      primaryLabel: l10n.onboardingConfirmCta,
      onPrimaryPressed: () => _handleConfirm(context, isCandidate: false),
      maxContentWidth: _defaultOnboardingCardMaxWidth,
    );
  }

  Widget _buildOnboardingCard({
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    IconData primaryIcon = Icons.check_circle_outline_rounded,
    Widget? body,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    IconData secondaryIcon = Icons.skip_next_rounded,
    String? tertiaryLabel,
    VoidCallback? onTertiaryPressed,
    bool primaryEnabled = true,
    bool showHeaderMedallion = true,
    int? stepIndex,
    int? totalSteps,
    String? stepLabel,
    double maxContentWidth = _defaultOnboardingCardMaxWidth,
  }) {
    return OnboardingCardBaseLayout(
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimaryPressed: onPrimaryPressed,
      primaryIcon: primaryIcon,
      body: body,
      secondaryLabel: secondaryLabel,
      onSecondaryPressed: onSecondaryPressed,
      secondaryIcon: secondaryIcon,
      tertiaryLabel: tertiaryLabel,
      onTertiaryPressed: onTertiaryPressed,
      primaryEnabled: primaryEnabled,
      showHeaderMedallion: showHeaderMedallion,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      stepLabel: stepLabel,
      maxContentWidth: maxContentWidth,
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
        final profileCubit = context.read<ProfileCubit>();
        final workStyleSkipped = resolvedOnboardingState.workStyleSkipped;
        final onboardingProfile = CandidateOnboardingProfile(
          targetRole: resolvedOnboardingState.targetRole.trim(),
          preferredLocation: resolvedOnboardingState.preferredLocation.trim(),
          preferredModality: resolvedOnboardingState.preferredModality.trim(),
          preferredSeniority: resolvedOnboardingState.preferredSeniority.trim(),
          workStyleSkipped: workStyleSkipped,
          startOfDayPreference: _normalizeOptional(
            resolvedOnboardingState.startOfDayPreference,
            workStyleSkipped: workStyleSkipped,
          ),
          feedbackPreference: _normalizeOptional(
            resolvedOnboardingState.feedbackPreference,
            workStyleSkipped: workStyleSkipped,
          ),
          structurePreference: _normalizeOptional(
            resolvedOnboardingState.structurePreference,
            workStyleSkipped: workStyleSkipped,
          ),
          taskPacePreference: _normalizeOptional(
            resolvedOnboardingState.taskPacePreference,
            workStyleSkipped: workStyleSkipped,
          ),
        );
        final repository = context.read<ProfileRepository>();
        final saved = await _persistCandidateOnboardingProfile(
          repository: repository,
          uid: uid,
          onboardingProfile: onboardingProfile,
        );
        if (saved) {
          unawaited(profileCubit.refresh());
        }
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

  String? _normalizeOptional(String value, {required bool workStyleSkipped}) {
    if (workStyleSkipped) return null;
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<bool> _persistCandidateOnboardingProfile({
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
      return true;
    } catch (_) {
      // If onboarding profile save fails, we still complete onboarding navigation.
      return false;
    }
  }
}
