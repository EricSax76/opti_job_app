import 'package:flutter/material.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step_view_model.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_intro_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_profile_basics_step.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/candidate_onboarding_steps/candidate_onboarding_work_style_step.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class CandidateOnboardingStepViewModelFactory {
  const CandidateOnboardingStepViewModelFactory();

  CandidateOnboardingStepViewModel build({
    required CandidateOnboardingState state,
    required CandidateOnboardingCubit cubit,
    required String candidateName,
    required AppLocalizations l10n,
  }) {
    final previousAction = state.canGoBack ? cubit.previousStep : null;
    final backLabel = state.canGoBack ? l10n.onboardingCandidateBackCta : null;

    return switch (state.currentStep) {
      CandidateOnboardingStep.introWelcome => _buildIntroStep(
        title: l10n.onboardingCandidateWelcomeTitle(candidateName),
        message: l10n.onboardingCandidateWelcomeMessage,
        icon: Icons.auto_awesome_rounded,
        headline: l10n.onboardingCandidateWelcomeHeadline,
        description: l10n.onboardingCandidateWelcomeDescription,
        highlights: [
          l10n.onboardingCandidateWelcomeHighlightPrioritizedOffers,
          l10n.onboardingCandidateWelcomeHighlightCompatibilitySignals,
          l10n.onboardingCandidateWelcomeHighlightShortProcess,
        ],
        primaryLabel: l10n.onboardingCandidateNextCta,
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.introSmartMatches => _buildIntroStep(
        title: l10n.onboardingCandidateSmartMatchesTitle,
        message: l10n.onboardingCandidateSmartMatchesMessage,
        icon: Icons.insights_rounded,
        headline: l10n.onboardingCandidateSmartMatchesHeadline,
        description: l10n.onboardingCandidateSmartMatchesDescription,
        highlights: [
          l10n.onboardingCandidateSmartMatchesHighlightFilters,
          l10n.onboardingCandidateSmartMatchesHighlightGroupedOffers,
          l10n.onboardingCandidateSmartMatchesHighlightLessFiltering,
        ],
        primaryLabel: l10n.onboardingCandidateNextCta,
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.introControl => _buildIntroStep(
        title: l10n.onboardingCandidateControlTitle,
        message: l10n.onboardingCandidateControlMessage,
        icon: Icons.verified_user_outlined,
        headline: l10n.onboardingCandidateControlHeadline,
        description: l10n.onboardingCandidateControlDescription,
        highlights: [
          l10n.onboardingCandidateControlHighlightOptionalQuestions,
          l10n.onboardingCandidateControlHighlightSkipAndReturn,
          l10n.onboardingCandidateControlHighlightCulturalFit,
        ],
        primaryLabel: l10n.onboardingCandidateContinueCta,
        onPrimaryPressed: cubit.nextStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.workStyle => _buildBaseStep(
        title: l10n.onboardingCandidateWorkStyleTitle,
        message: l10n.onboardingCandidateWorkStyleMessage,
        body: CandidateOnboardingWorkStyleStep(
          startOfDayPreference: state.startOfDayPreference,
          feedbackPreference: state.feedbackPreference,
          structurePreference: state.structurePreference,
          taskPacePreference: state.taskPacePreference,
          onStartOfDayChanged: cubit.updateStartOfDayPreference,
          onFeedbackChanged: cubit.updateFeedbackPreference,
          onStructureChanged: cubit.updateStructurePreference,
          onTaskPaceChanged: cubit.updateTaskPacePreference,
        ),
        primaryLabel: l10n.onboardingCandidateContinueCta,
        primaryIcon: Icons.arrow_forward_rounded,
        onPrimaryPressed: cubit.nextStep,
        secondaryLabel: l10n.onboardingCandidateSkipForNowCta,
        onSecondaryPressed: cubit.skipCurrentStep,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
      CandidateOnboardingStep.profileBasics => _buildBaseStep(
        title: l10n.onboardingCandidateProfileBasicsTitle,
        message: l10n.onboardingCandidateProfileBasicsMessage,
        body: CandidateOnboardingProfileBasicsStep(
          targetRole: state.targetRole,
          preferredLocation: state.preferredLocation,
          preferredModality: state.preferredModality,
          preferredSeniority: state.preferredSeniority,
          validationMessage: _resolveValidationMessage(
            validationMessage: state.validationMessage,
            l10n: l10n,
          ),
          onTargetRoleChanged: cubit.updateTargetRole,
          onPreferredLocationChanged: cubit.updatePreferredLocation,
          onPreferredModalityChanged: cubit.updatePreferredModality,
          onPreferredSeniorityChanged: cubit.updatePreferredSeniority,
        ),
        primaryLabel: l10n.onboardingCandidateFinishCta,
        primaryIcon: Icons.check_circle_outline_rounded,
        onPrimaryPressed: cubit.completeOnboarding,
        primaryEnabled: state.hasMinimumProfileData,
        backLabel: backLabel,
        onBackPressed: previousAction,
      ),
    };
  }

  String? _resolveValidationMessage({
    required String? validationMessage,
    required AppLocalizations l10n,
  }) {
    if (validationMessage == null) return null;
    if (validationMessage ==
        CandidateOnboardingCubit.minimumProfileDataValidationKey) {
      return l10n.onboardingCandidateValidationMinimumProfileData;
    }
    return validationMessage;
  }

  CandidateOnboardingStepViewModel _buildIntroStep({
    required String title,
    required String message,
    required IconData icon,
    required String headline,
    required String description,
    required List<String> highlights,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    required String? backLabel,
    required VoidCallback? onBackPressed,
  }) {
    return _buildBaseStep(
      title: title,
      message: message,
      body: CandidateOnboardingIntroStep(
        icon: icon,
        headline: headline,
        description: description,
        highlights: highlights,
      ),
      primaryLabel: primaryLabel,
      primaryIcon: Icons.arrow_forward_rounded,
      onPrimaryPressed: onPrimaryPressed,
      backLabel: backLabel,
      onBackPressed: onBackPressed,
    );
  }

  CandidateOnboardingStepViewModel _buildBaseStep({
    required String title,
    required String message,
    required Widget body,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimaryPressed,
    required String? backLabel,
    required VoidCallback? onBackPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    bool primaryEnabled = true,
  }) {
    return CandidateOnboardingStepViewModel(
      title: title,
      message: message,
      body: body,
      primaryLabel: primaryLabel,
      primaryIcon: primaryIcon,
      onPrimaryPressed: onPrimaryPressed,
      secondaryLabel: secondaryLabel,
      onSecondaryPressed: onSecondaryPressed,
      tertiaryLabel: backLabel,
      onTertiaryPressed: onBackPressed,
      primaryEnabled: primaryEnabled,
    );
  }
}
