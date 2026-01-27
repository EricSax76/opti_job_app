import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

enum JobOffersStatus { initial, loading, success, failure }

class JobOffersState {
  const JobOffersState({
    this.status = JobOffersStatus.initial,
    this.offers = const [],
    this.filteredOffers,
    this.companiesById = const {},
    this.errorMessage,
    this.selectedJobType,
    this.activeFilters = const JobOfferFilters(),
  });

  final JobOffersStatus status;
  final List<JobOffer> offers;
  final List<JobOffer>? filteredOffers;
  final Map<int, Company> companiesById;
  final String? errorMessage;
  final String? selectedJobType;
  final JobOfferFilters activeFilters;

  List<JobOffer> get displayedOffers => filteredOffers ?? offers;

  JobOffersState copyWith({
    JobOffersStatus? status,
    List<JobOffer>? offers,
    List<JobOffer>? filteredOffers,
    Map<int, Company>? companiesById,
    String? errorMessage,
    String? selectedJobType,
    JobOfferFilters? activeFilters,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return JobOffersState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      filteredOffers: clearFilters ? null : (filteredOffers ?? this.filteredOffers),
      companiesById: companiesById ?? this.companiesById,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedJobType: selectedJobType ?? this.selectedJobType,
      activeFilters: clearFilters ? const JobOfferFilters() : (activeFilters ?? this.activeFilters),
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
      final companiesById = await _loadCompanies(offers);
      emit(
        state.copyWith(
          status: JobOffersStatus.success,
          offers: offers,
          companiesById: companiesById,
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

  void applyFilters(JobOfferFilters filters) {
    final allOffers = state.offers;
    
    if (!filters.hasActiveFilters) {
      emit(state.copyWith(
        activeFilters: filters,
        filteredOffers: null,
        clearFilters: true,
      ));
      return;
    }

    final filtered = allOffers.where((offer) {
      // Search query filter
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final query = filters.searchQuery!.toLowerCase();
        final titleMatch = offer.title.toLowerCase().contains(query);
        final descMatch = offer.description.toLowerCase().contains(query);
        final companyMatch = (offer.companyName?.toLowerCase() ?? '').contains(query);
        if (!titleMatch && !descMatch && !companyMatch) return false;
      }

      // Location filter
      if (filters.location != null && filters.location!.isNotEmpty) {
        if (!offer.location.toLowerCase().contains(filters.location!.toLowerCase())) {
          return false;
        }
      }

      // Job type filter
      if (filters.jobType != null) {
        if (offer.jobType != filters.jobType) return false;
      }

      // Salary range filter
      if (filters.salaryMin != null || filters.salaryMax != null) {
        final minSalary = _parseSalary(offer.salaryMin);
        final maxSalary = _parseSalary(offer.salaryMax);
        
        if (filters.salaryMin != null && maxSalary != null) {
          if (maxSalary < filters.salaryMin!) return false;
        }
        
        if (filters.salaryMax != null && minSalary != null) {
          if (minSalary > filters.salaryMax!) return false;
        }
      }

      // Education filter
      if (filters.education != null) {
        if (offer.education != filters.education) return false;
      }

      // Company name filter
      if (filters.companyName != null && filters.companyName!.isNotEmpty) {
        final companyName = offer.companyName ?? '';
        if (!companyName.toLowerCase().contains(filters.companyName!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    emit(state.copyWith(
      activeFilters: filters,
      filteredOffers: filtered,
    ));
  }

  double? _parseSalary(String? salaryStr) {
    if (salaryStr == null || salaryStr.isEmpty) return null;
    
    // Remove common formatting characters
    final cleaned = salaryStr.replaceAll(RegExp(r'[€$,\s]'), '');
    return double.tryParse(cleaned);
  }

  Future<Map<int, Company>> _loadCompanies(List<JobOffer> offers) async {
    final companyIds =
        offers.map((offer) => offer.companyId).whereType<int>().toSet().toList();
    if (companyIds.isEmpty) return const {};

    try {
      return await _profileRepository.fetchCompaniesByIds(companyIds);
    } catch (_) {
      return const {};
    }
  }
}
