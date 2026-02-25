import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/home/logic/candidate_onboarding_step_view_model_factory.dart';
import 'package:opti_job_app/home/widgets/onboarding_card_base.dart';

class CandidateOnboardingFlow extends StatelessWidget {
  const CandidateOnboardingFlow({
    super.key,
    required this.candidateName,
    required this.onCompleted,
  });

  static const CandidateOnboardingStepViewModelFactory _viewModelFactory =
      CandidateOnboardingStepViewModelFactory();

  final String candidateName;
  final ValueChanged<CandidateOnboardingState> onCompleted;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CandidateOnboardingCubit, CandidateOnboardingState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus ==
            CandidateOnboardingSubmissionStatus.completed) {
          onCompleted(state);
        }
      },
      builder: (context, state) {
        final cubit = context.read<CandidateOnboardingCubit>();
        final stepViewModel = _viewModelFactory.build(
          state: state,
          cubit: cubit,
          candidateName: candidateName,
        );

        return OnboardingCardBase(
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
          stepLabel: 'Paso ${state.currentStepIndex} de ${state.totalSteps}',
          maxContentWidth: 620,
        );
      },
    );
  }
}
