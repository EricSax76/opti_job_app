import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:infojobs_flutter_app/data/models/job_offer.dart';
import 'package:infojobs_flutter_app/data/repositories/job_offer_repository.dart';

enum JobOffersStatus { initial, loading, success, failure }

class JobOffersState {
  const JobOffersState({
    this.status = JobOffersStatus.initial,
    this.offers = const [],
    this.errorMessage,
    this.selectedJobType,
  });

  final JobOffersStatus status;
  final List<JobOffer> offers;
  final String? errorMessage;
  final String? selectedJobType;

  JobOffersState copyWith({
    JobOffersStatus? status,
    List<JobOffer>? offers,
    String? errorMessage,
    String? selectedJobType,
    bool clearError = false,
  }) {
    return JobOffersState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedJobType: selectedJobType ?? this.selectedJobType,
    );
  }
}

class JobOffersCubit extends Cubit<JobOffersState> {
  JobOffersCubit(this._repository) : super(const JobOffersState());

  final JobOfferRepository _repository;

  Future<void> loadOffers({String? jobType}) async {
    final filter = jobType ?? state.selectedJobType;
    emit(
      state.copyWith(
        status: JobOffersStatus.loading,
        selectedJobType: jobType ?? state.selectedJobType,
        clearError: true,
      ),
    );
    try {
      final offers = await _repository.fetchAll(jobType: filter);
      emit(state.copyWith(status: JobOffersStatus.success, offers: offers));
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOffersStatus.failure,
          errorMessage: 'No se pudieron cargar las ofertas.',
        ),
      );
    }
  }

  void selectJobType(String? jobType) {
    emit(state.copyWith(selectedJobType: jobType));
    loadOffers(jobType: jobType);
  }
}
