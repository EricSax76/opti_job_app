import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:infojobs_flutter_app/data/models/job_offer.dart';
import 'package:infojobs_flutter_app/data/repositories/job_offer_repository.dart';

enum JobOfferDetailStatus { initial, loading, success, failure }

class JobOfferDetailState {
  const JobOfferDetailState({
    this.status = JobOfferDetailStatus.initial,
    this.offer,
    this.errorMessage,
  });

  final JobOfferDetailStatus status;
  final JobOffer? offer;
  final String? errorMessage;

  JobOfferDetailState copyWith({
    JobOfferDetailStatus? status,
    JobOffer? offer,
    String? errorMessage,
    bool clearError = false,
    bool clearOffer = false,
  }) {
    return JobOfferDetailState(
      status: status ?? this.status,
      offer: clearOffer ? null : offer ?? this.offer,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class JobOfferDetailCubit extends Cubit<JobOfferDetailState> {
  JobOfferDetailCubit(this._repository) : super(const JobOfferDetailState());

  final JobOfferRepository _repository;

  Future<void> loadOffer(int id) async {
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.loading,
        clearError: true,
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
}
