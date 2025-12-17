import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';

enum JobOfferFormStatus { idle, submitting, success, failure }

class JobOfferFormState {
  const JobOfferFormState({
    this.status = JobOfferFormStatus.idle,
    this.message,
  });

  final JobOfferFormStatus status;
  final String? message;

  JobOfferFormState copyWith({
    JobOfferFormStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return JobOfferFormState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class JobOfferFormCubit extends Cubit<JobOfferFormState> {
  JobOfferFormCubit(this._repository) : super(const JobOfferFormState());

  final JobOfferRepository _repository;

  Future<void> submit(JobOfferPayload payload) async {
    emit(
      state.copyWith(status: JobOfferFormStatus.submitting, clearMessage: true),
    );
    try {
      await _repository.create(payload);
      emit(
        state.copyWith(
          status: JobOfferFormStatus.success,
          message: 'Oferta publicada con éxito.',
        ),
      );
      emit(state.copyWith(status: JobOfferFormStatus.idle, clearMessage: true));
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferFormStatus.failure,
          message: 'Error al publicar la oferta. Intenta nuevamente.',
        ),
      );
      emit(state.copyWith(status: JobOfferFormStatus.idle, clearMessage: true));
    }
  }
}
