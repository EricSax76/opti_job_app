import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/models/candidate_onboarding_step.dart';

class CandidateOnboardingCubit extends Cubit<CandidateOnboardingState> {
  CandidateOnboardingCubit() : super(const CandidateOnboardingState());

  static const String minimumProfileDataValidationKey =
      'onboarding_candidate_validation_minimum_profile_data';

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
      final nextStep = state.currentStep.next;
      if (nextStep == null) return;
      emit(
        state.copyWith(
          currentStep: nextStep,
          workStyleSkipped: true,
          startOfDayPreference: '',
          feedbackPreference: '',
          structurePreference: '',
          taskPacePreference: '',
          clearValidation: true,
        ),
      );
    });
  }

  void updateStartOfDayPreference(String value) {
    _updateField(
      (current) => current.copyWith(
        startOfDayPreference: value,
        workStyleSkipped: false,
      ),
    );
  }

  void updateFeedbackPreference(String value) {
    _updateField(
      (current) =>
          current.copyWith(feedbackPreference: value, workStyleSkipped: false),
    );
  }

  void updateStructurePreference(String value) {
    _updateField(
      (current) =>
          current.copyWith(structurePreference: value, workStyleSkipped: false),
    );
  }

  void updateTaskPacePreference(String value) {
    _updateField(
      (current) =>
          current.copyWith(taskPacePreference: value, workStyleSkipped: false),
    );
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
          state.copyWith(validationMessage: minimumProfileDataValidationKey),
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

  void _moveToStep(CandidateOnboardingStep? targetStep) {
    if (targetStep == null) return;
    emit(state.copyWith(currentStep: targetStep, clearValidation: true));
  }

  void _updateField(
    CandidateOnboardingState Function(CandidateOnboardingState current) update,
  ) {
    _runIfActive(() {
      emit(update(state).copyWith(clearValidation: true));
    });
  }
}
