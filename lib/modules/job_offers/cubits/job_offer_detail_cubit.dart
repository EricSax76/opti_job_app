import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

enum JobOfferDetailStatus { initial, loading, success, failure, applying }

class JobOfferDetailState {
  const JobOfferDetailState({
    this.status = JobOfferDetailStatus.initial,
    this.offer,
    this.application,
    this.errorMessage,
    this.successMessage,
  });

  final JobOfferDetailStatus status;
  final JobOffer? offer;
  final Application? application;
  final String? errorMessage;
  final String? successMessage;

  JobOfferDetailState copyWith({
    JobOfferDetailStatus? status,
    JobOffer? offer,
    Application? application,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearOffer = false,
    bool clearApplication = false,
  }) {
    return JobOfferDetailState(
      status: status ?? this.status,
      offer: clearOffer ? null : offer ?? this.offer,
      application: clearApplication ? null : application ?? this.application,
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

  Future<void> loadOffer(String id, {String? candidateUid}) async {
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.loading,
        clearError: true,
        clearSuccess: true,
        clearOffer: true,
        clearApplication: true,
      ),
    );
    try {
      final offer = await _repository.fetchById(id);
      Application? application;
      if (candidateUid != null && candidateUid.isNotEmpty) {
        try {
          application = await _applicationService.getApplicationForCandidateOffer(
            jobOfferId: offer.id,
            candidateUid: candidateUid,
          );
        } catch (_) {
          application = null;
        }
      }
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.success,
          offer: offer,
          application: application,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'No se pudo cargar la oferta seleccionada.',
        ),
      );
    }
  }

  Future<void> apply({
    required Candidate candidate,
    required JobOffer offer,
  }) async {
    if (state.application != null) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'Ya te has postulado a esta oferta.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.applying,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _applicationService.createApplication(
        candidate: candidate,
        jobOffer: offer,
        candidateProfileId: candidate.id,
      );
      final application = await _applicationService.getApplicationForCandidateOffer(
        jobOfferId: offer.id,
        candidateUid: candidate.uid,
      );
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.success,
          application: application,
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
