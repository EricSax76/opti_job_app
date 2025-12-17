import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';

enum JobOfferDetailStatus { initial, loading, success, failure, applying }

class JobOfferDetailState {
  const JobOfferDetailState({
    this.status = JobOfferDetailStatus.initial,
    this.offer,
    this.errorMessage,
    this.successMessage,
  });

  final JobOfferDetailStatus status;
  final JobOffer? offer;
  final String? errorMessage;
  final String? successMessage;

  JobOfferDetailState copyWith({
    JobOfferDetailStatus? status,
    JobOffer? offer,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearOffer = false,
  }) {
    return JobOfferDetailState(
      status: status ?? this.status,
      offer: clearOffer ? null : offer ?? this.offer,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class JobOfferDetailCubit extends Cubit<JobOfferDetailState> {
  JobOfferDetailCubit(this._repository, this._applicationService)
    : super(const JobOfferDetailState());

  final JobOfferRepository _repository;
  final ApplicationService _applicationService;

  Future<void> loadOffer(int id) async {
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.loading,
        clearError: true,
        clearSuccess: true,
        clearOffer: true,
      ),
    );
    try {
      final offer = await _repository.fetchById(id);
      emit(state.copyWith(status: JobOfferDetailStatus.success, offer: offer));
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'No se pudo cargar la oferta seleccionada.',
        ),
      );
    }
  }

  Future<void> apply(int candidateId, int jobOfferId) async {
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.applying,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _applicationService.createApplication(
        candidateId: candidateId,
        jobOfferId: jobOfferId,
      );
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.success,
          successMessage: '¡Te has postulado a esta oferta!',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'Ya te has postulado a esta oferta.',
        ),
      );
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
