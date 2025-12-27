import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

enum JobOffersStatus { initial, loading, success, failure }

class JobOffersState {
  const JobOffersState({
    this.status = JobOffersStatus.initial,
    this.offers = const [],
    this.companyNamesById = const {},
    this.errorMessage,
    this.selectedJobType,
  });

  final JobOffersStatus status;
  final List<JobOffer> offers;
  final Map<int, String> companyNamesById;
  final String? errorMessage;
  final String? selectedJobType;

  JobOffersState copyWith({
    JobOffersStatus? status,
    List<JobOffer>? offers,
    Map<int, String>? companyNamesById,
    String? errorMessage,
    String? selectedJobType,
    bool clearError = false,
  }) {
    return JobOffersState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      companyNamesById: companyNamesById ?? this.companyNamesById,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedJobType: selectedJobType ?? this.selectedJobType,
    );
  }
}

class JobOffersCubit extends Cubit<JobOffersState> {
  JobOffersCubit(this._repository, {required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(const JobOffersState());

  final JobOfferRepository _repository;
  final ProfileRepository _profileRepository;

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
      final companyNamesById = await _loadCompanyNames(offers);
      emit(
        state.copyWith(
          status: JobOffersStatus.success,
          offers: offers,
          companyNamesById: companyNamesById,
        ),
      );
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

  Future<Map<int, String>> _loadCompanyNames(List<JobOffer> offers) async {
    final companyIds =
        offers.map((offer) => offer.companyId).whereType<int>().toSet().toList();
    if (companyIds.isEmpty) return const {};

    try {
      final companiesById = await _profileRepository.fetchCompaniesByIds(
        companyIds,
      );
      return {
        for (final entry in companiesById.entries) entry.key: entry.value.name,
      };
    } catch (_) {
      return const {};
    }
  }
}
