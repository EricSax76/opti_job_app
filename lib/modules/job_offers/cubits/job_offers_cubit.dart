import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

enum JobOffersStatus { initial, loading, success, failure }

class JobOffersState {
  const JobOffersState({
    this.status = JobOffersStatus.initial,
    this.offers = const [],
    this.filteredOffers,
    this.companiesById = const {},
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.selectedJobType,
    this.activeFilters = const JobOfferFilters(),
  });

  final JobOffersStatus status;
  final List<JobOffer> offers;
  final List<JobOffer>? filteredOffers;
  final Map<int, Company> companiesById;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? selectedJobType;
  final JobOfferFilters activeFilters;

  List<JobOffer> get displayedOffers => filteredOffers ?? offers;

  JobOffersState copyWith({
    JobOffersStatus? status,
    List<JobOffer>? offers,
    List<JobOffer>? filteredOffers,
    Map<int, Company>? companiesById,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? selectedJobType,
    JobOfferFilters? activeFilters,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return JobOffersState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      filteredOffers: clearFilters
          ? null
          : (filteredOffers ?? this.filteredOffers),
      companiesById: companiesById ?? this.companiesById,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedJobType: selectedJobType ?? this.selectedJobType,
      activeFilters: clearFilters
          ? const JobOfferFilters()
          : (activeFilters ?? this.activeFilters),
    );
  }
}

class JobOffersCubit extends Cubit<JobOffersState> {
  static const int _pageSize = 20;

  JobOffersCubit(
    this._repository, {
    required ProfileRepository profileRepository,
  }) : _profileRepository = profileRepository,
       super(const JobOffersState());

  final JobOfferRepository _repository;
  final ProfileRepository _profileRepository;

  JobOffersPageCursor? _nextPageCursor;
  int _requestSequence = 0;

  Future<void> loadOffers({String? jobType, bool forceRefresh = false}) async {
    final selectedJobType = _normalizeJobType(jobType) ?? state.selectedJobType;
    final previousSelectedJobType = state.selectedJobType;
    final sameQuery =
        _normalizeJobType(selectedJobType) ==
        _normalizeJobType(previousSelectedJobType);

    if (!forceRefresh &&
        sameQuery &&
        (state.status == JobOffersStatus.loading ||
            state.isRefreshing ||
            state.isLoadingMore)) {
      return;
    }
    if (!forceRefresh &&
        sameQuery &&
        state.status == JobOffersStatus.success &&
        state.offers.isNotEmpty) {
      return;
    }

    final requestId = ++_requestSequence;
    final shouldShowBlockingLoader = state.offers.isEmpty;
    emit(
      state.copyWith(
        status: shouldShowBlockingLoader
            ? JobOffersStatus.loading
            : state.status,
        selectedJobType: selectedJobType,
        isRefreshing: !shouldShowBlockingLoader,
        isLoadingMore: false,
        hasMore: shouldShowBlockingLoader ? true : state.hasMore,
        clearError: true,
      ),
    );

    try {
      final page = await _repository.fetchPage(
        jobType: selectedJobType,
        limit: _pageSize,
      );
      if (requestId != _requestSequence) return;

      _nextPageCursor = page.nextPageCursor;
      final companiesById = await _loadCompanies(
        page.offers,
        seed: state.companiesById,
      );
      if (requestId != _requestSequence) return;

      final filteredOffers = _filterOffers(page.offers, state.activeFilters);
      emit(
        state.copyWith(
          status: JobOffersStatus.success,
          offers: page.offers,
          filteredOffers: filteredOffers,
          companiesById: companiesById,
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: page.hasMore,
          clearError: true,
        ),
      );
    } catch (_) {
      if (requestId != _requestSequence) return;
      _nextPageCursor = null;

      if (!shouldShowBlockingLoader && state.offers.isNotEmpty) {
        emit(
          state.copyWith(
            status: JobOffersStatus.success,
            selectedJobType: previousSelectedJobType,
            isRefreshing: false,
            isLoadingMore: false,
            errorMessage: 'No se pudieron actualizar las ofertas.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JobOffersStatus.failure,
          offers: const [],
          filteredOffers: null,
          companiesById: const {},
          isRefreshing: false,
          isLoadingMore: false,
          hasMore: false,
          errorMessage: 'No se pudieron cargar las ofertas.',
        ),
      );
    }
  }

  Future<void> loadMoreOffers() async {
    if (state.status != JobOffersStatus.success ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore ||
        _nextPageCursor == null) {
      return;
    }

    final requestId = _requestSequence;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final page = await _repository.fetchPage(
        jobType: state.selectedJobType,
        limit: _pageSize,
        startAfter: _nextPageCursor,
      );
      if (requestId != _requestSequence) return;

      _nextPageCursor = page.nextPageCursor;
      final mergedOffers = <JobOffer>[...state.offers, ...page.offers];
      final companiesById = await _loadCompanies(
        page.offers,
        seed: state.companiesById,
      );
      if (requestId != _requestSequence) return;

      final filteredOffers = _filterOffers(mergedOffers, state.activeFilters);
      emit(
        state.copyWith(
          status: JobOffersStatus.success,
          offers: mergedOffers,
          filteredOffers: filteredOffers,
          companiesById: companiesById,
          isLoadingMore: false,
          isRefreshing: false,
          hasMore: page.hasMore,
          clearError: true,
        ),
      );
    } catch (_) {
      if (requestId != _requestSequence) return;
      emit(
        state.copyWith(
          status: JobOffersStatus.success,
          isLoadingMore: false,
          errorMessage: 'No se pudieron cargar más ofertas.',
        ),
      );
    }
  }

  void selectJobType(String? jobType) {
    final normalizedJobType = _normalizeJobType(jobType);
    final currentJobType = _normalizeJobType(state.selectedJobType);
    if (normalizedJobType == currentJobType &&
        state.status != JobOffersStatus.failure) {
      return;
    }
    loadOffers(jobType: normalizedJobType, forceRefresh: true);
  }

  void applyFilters(JobOfferFilters filters) {
    if (filters == state.activeFilters) return;

    if (!filters.hasActiveFilters) {
      emit(
        state.copyWith(
          activeFilters: filters,
          filteredOffers: null,
          clearFilters: true,
        ),
      );
      return;
    }

    final filtered = _filterOffers(state.offers, filters);
    emit(state.copyWith(activeFilters: filters, filteredOffers: filtered));
  }

  List<JobOffer>? _filterOffers(
    List<JobOffer> offers,
    JobOfferFilters filters,
  ) {
    if (!filters.hasActiveFilters) return null;

    final query = filters.searchQuery?.trim().toLowerCase();
    final location = filters.location?.trim().toLowerCase();
    final companyNameFilter = filters.companyName?.trim().toLowerCase();

    return offers
        .where((offer) {
          if (query != null && query.isNotEmpty) {
            final titleMatch = offer.title.toLowerCase().contains(query);
            final descMatch = offer.description.toLowerCase().contains(query);
            final companyMatch = (offer.companyName?.toLowerCase() ?? '')
                .contains(query);
            if (!titleMatch && !descMatch && !companyMatch) return false;
          }

          if (location != null && location.isNotEmpty) {
            if (!offer.location.toLowerCase().contains(location)) {
              return false;
            }
          }

          if (filters.jobType != null && offer.jobType != filters.jobType) {
            return false;
          }

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

          if (filters.education != null &&
              offer.education != filters.education) {
            return false;
          }

          if (companyNameFilter != null && companyNameFilter.isNotEmpty) {
            final companyName = offer.companyName ?? '';
            if (!companyName.toLowerCase().contains(companyNameFilter)) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  double? _parseSalary(String? salaryStr) {
    if (salaryStr == null || salaryStr.isEmpty) return null;

    // Remove common formatting characters
    final cleaned = salaryStr.replaceAll(RegExp(r'[€$,\s]'), '');
    return double.tryParse(cleaned);
  }

  Future<Map<int, Company>> _loadCompanies(
    List<JobOffer> offers, {
    Map<int, Company>? seed,
  }) async {
    final resolved = <int, Company>{...(seed ?? const <int, Company>{})};
    final companyIds = offers
        .map((offer) => offer.companyId)
        .whereType<int>()
        .where((id) => id > 0)
        .where((id) => !resolved.containsKey(id))
        .toSet()
        .toList(growable: false);
    if (companyIds.isEmpty) return resolved;

    try {
      final fetched = await _profileRepository.fetchCompaniesByIds(companyIds);
      if (fetched.isNotEmpty) {
        resolved.addAll(fetched);
      }
      return resolved;
    } catch (_) {
      return resolved;
    }
  }

  String? _normalizeJobType(String? jobType) {
    final normalized = jobType?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
