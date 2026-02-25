import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/home/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/home/models/candidate_onboarding_step.dart';

class CandidateOnboardingCubit extends Cubit<CandidateOnboardingState> {
  CandidateOnboardingCubit() : super(const CandidateOnboardingState());

  void nextStep() {
    _runIfActive(() {
      if (state.currentStep == CandidateOnboardingStep.profileBasics) {
        completeOnboarding();
        return;
      }
      _moveToStep(state.currentStep.next);
    });
  }

  void previousStep() {
    _runIfActive(() => _moveToStep(state.currentStep.previous));
  }

  void goToStep(CandidateOnboardingStep step) {
    _runIfActive(() => _moveToStep(step));
  }

  void skipCurrentStep() {
    _runIfActive(() {
      if (!state.canSkipCurrentStep) return;
      _moveToStep(state.currentStep.next, markWorkStyleAsSkipped: true);
    });
  }

  void updateStartOfDayPreference(String value) {
    _updateField((current) => current.copyWith(startOfDayPreference: value));
  }

  void updateFeedbackPreference(String value) {
    _updateField((current) => current.copyWith(feedbackPreference: value));
  }

  void updateStructurePreference(String value) {
    _updateField((current) => current.copyWith(structurePreference: value));
  }

  void updateTaskPacePreference(String value) {
    _updateField((current) => current.copyWith(taskPacePreference: value));
  }

  void updateTargetRole(String value) {
    _updateField((current) => current.copyWith(targetRole: value));
  }

  void updatePreferredLocation(String value) {
    _updateField((current) => current.copyWith(preferredLocation: value));
  }

  void updatePreferredModality(String value) {
    _updateField((current) => current.copyWith(preferredModality: value));
  }

  void updatePreferredSeniority(String value) {
    _updateField((current) => current.copyWith(preferredSeniority: value));
  }

  void completeOnboarding() {
    _runIfActive(() {
      if (!state.hasMinimumProfileData) {
        emit(
          state.copyWith(
            validationMessage:
                'Completa rol objetivo, modalidad, ubicación y seniority para finalizar.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submissionStatus: CandidateOnboardingSubmissionStatus.completed,
          clearValidation: true,
        ),
      );
    });
  }

  void _runIfActive(void Function() action) {
    if (state.submissionStatus ==
        CandidateOnboardingSubmissionStatus.completed) {
      return;
    }
    action();
  }

  void _moveToStep(
    CandidateOnboardingStep? targetStep, {
    bool markWorkStyleAsSkipped = false,
  }) {
    if (targetStep == null) return;
    emit(
      state.copyWith(
        currentStep: targetStep,
        workStyleSkipped: markWorkStyleAsSkipped ? true : null,
        clearValidation: true,
      ),
    );
  }

  void _updateField(
    CandidateOnboardingState Function(CandidateOnboardingState current) update,
  ) {
    _runIfActive(() {
      emit(update(state).copyWith(clearValidation: true));
    });
  }
}
