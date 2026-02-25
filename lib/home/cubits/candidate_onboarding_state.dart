import 'package:equatable/equatable.dart';
import 'package:opti_job_app/home/models/candidate_onboarding_step.dart';

enum CandidateOnboardingSubmissionStatus { idle, completed }

class CandidateOnboardingState extends Equatable {
  const CandidateOnboardingState({
    this.currentStep = CandidateOnboardingStep.introWelcome,
    this.startOfDayPreference = '',
    this.feedbackPreference = '',
    this.structurePreference = '',
    this.taskPacePreference = '',
    this.targetRole = '',
    this.preferredLocation = '',
    this.preferredModality = '',
    this.preferredSeniority = '',
    this.workStyleSkipped = false,
    this.validationMessage,
    this.submissionStatus = CandidateOnboardingSubmissionStatus.idle,
  });

  final CandidateOnboardingStep currentStep;
  final String startOfDayPreference;
  final String feedbackPreference;
  final String structurePreference;
  final String taskPacePreference;
  final String targetRole;
  final String preferredLocation;
  final String preferredModality;
  final String preferredSeniority;
  final bool workStyleSkipped;
  final String? validationMessage;
  final CandidateOnboardingSubmissionStatus submissionStatus;

  int get currentStepIndex => currentStep.position;
  int get totalSteps => CandidateOnboardingStepX.orderedValues.length;
  bool get canGoBack => currentStep.previous != null;
  bool get canSkipCurrentStep => currentStep.isOptional;
  bool get isLastStep => currentStep == CandidateOnboardingStep.profileBasics;

  bool get hasMinimumProfileData =>
      targetRole.trim().isNotEmpty &&
      preferredLocation.trim().isNotEmpty &&
      preferredModality.trim().isNotEmpty &&
      preferredSeniority.trim().isNotEmpty;

  bool get canContinueCurrentStep {
    if (currentStep == CandidateOnboardingStep.profileBasics) {
      return hasMinimumProfileData;
    }
    return true;
  }

  CandidateOnboardingState copyWith({
    CandidateOnboardingStep? currentStep,
    String? startOfDayPreference,
    String? feedbackPreference,
    String? structurePreference,
    String? taskPacePreference,
    String? targetRole,
    String? preferredLocation,
    String? preferredModality,
    String? preferredSeniority,
    bool? workStyleSkipped,
    String? validationMessage,
    CandidateOnboardingSubmissionStatus? submissionStatus,
    bool clearValidation = false,
  }) {
    return CandidateOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      startOfDayPreference: startOfDayPreference ?? this.startOfDayPreference,
      feedbackPreference: feedbackPreference ?? this.feedbackPreference,
      structurePreference: structurePreference ?? this.structurePreference,
      taskPacePreference: taskPacePreference ?? this.taskPacePreference,
      targetRole: targetRole ?? this.targetRole,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      preferredModality: preferredModality ?? this.preferredModality,
      preferredSeniority: preferredSeniority ?? this.preferredSeniority,
      workStyleSkipped: workStyleSkipped ?? this.workStyleSkipped,
      validationMessage: clearValidation
          ? null
          : validationMessage ?? this.validationMessage,
      submissionStatus: submissionStatus ?? this.submissionStatus,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    startOfDayPreference,
    feedbackPreference,
    structurePreference,
    taskPacePreference,
    targetRole,
    preferredLocation,
    preferredModality,
    preferredSeniority,
    workStyleSkipped,
    validationMessage,
    submissionStatus,
  ];
}
