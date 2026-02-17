import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

part 'applicant_interaction_state.dart';

class ApplicantInteractionCubit extends Cubit<ApplicantInteractionState> {
  ApplicantInteractionCubit(this._interviewRepository)
      : super(const ApplicantInteractionInitial());

  final InterviewRepository _interviewRepository;

  Future<void> startInterview(String applicationId) async {
    emit(const ApplicantInteractionLoading());
    try {
      final interviewId = await _interviewRepository.startInterview(applicationId);
      emit(ApplicantInteractionSuccess(interviewId));
    } on FirebaseFunctionsException catch (e) {
      final message = e.message?.trim().isNotEmpty == true
          ? e.message!
          : 'No se pudo iniciar la entrevista.';
      emit(ApplicantInteractionFailure('Error (${e.code}): $message'));
    } catch (e) {
      emit(ApplicantInteractionFailure('Error: $e'));
    }
  }

  void reset() {
    emit(const ApplicantInteractionInitial());
  }
}
