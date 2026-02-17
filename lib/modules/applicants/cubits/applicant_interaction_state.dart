part of 'applicant_interaction_cubit.dart';

sealed class ApplicantInteractionState {
  const ApplicantInteractionState();
}

class ApplicantInteractionInitial extends ApplicantInteractionState {
  const ApplicantInteractionInitial();
}

class ApplicantInteractionLoading extends ApplicantInteractionState {
  const ApplicantInteractionLoading();
}

class ApplicantInteractionSuccess extends ApplicantInteractionState {
  const ApplicantInteractionSuccess(this.interviewId);

  final String interviewId;
}

class ApplicantInteractionFailure extends ApplicantInteractionState {
  const ApplicantInteractionFailure(this.message);

  final String message;
}
