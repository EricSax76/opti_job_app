import 'package:flutter/widgets.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_list_view_model.dart';

class JobOfferListLogic {
  const JobOfferListLogic._();

  static const double paginationThreshold = 280;

  static bool shouldLoadInitialOffers(JobOffersState state) {
    return state.status == JobOffersStatus.initial;
  }

  static bool shouldShowRefreshError({
    required JobOffersState previous,
    required JobOffersState current,
  }) {
    return previous.errorMessage != current.errorMessage &&
        nonBlockingErrorMessage(current) != null;
  }

  static String? nonBlockingErrorMessage(JobOffersState state) {
    if (state.status != JobOffersStatus.success) return null;
    final message = _normalizeValue(state.errorMessage);
    return message;
  }

  static JobOfferListViewModel buildViewModel(JobOffersState state) {
    final selectedJobType = _normalizeValue(state.selectedJobType);
    final items = state.offers
        .map(
          (offer) =>
              _buildItem(offer: offer, companiesById: state.companiesById),
        )
        .toList(growable: false);

    return JobOfferListViewModel(
      items: items,
      availableJobTypes: _mergeJobTypes(
        existing: state.availableJobTypes,
        offers: state.offers,
        selectedJobType: selectedJobType,
      ),
      selectedJobType: selectedJobType,
      isRefreshing: state.isRefreshing,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
    );
  }

  static bool shouldLoadMore({
    required ScrollNotification notification,
    required bool isLoadingMore,
    required bool isRefreshing,
    required bool hasMore,
  }) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (isLoadingMore || isRefreshing || !hasMore) return false;

    final pixels = notification.metrics.pixels;
    final max = notification.metrics.maxScrollExtent;
    return max - pixels <= paginationThreshold;
  }

  static JobOfferListItemViewModel _buildItem({
    required JobOffer offer,
    required Map<int, Company> companiesById,
  }) {
    final company = offer.companyId == null
        ? null
        : companiesById[offer.companyId!];
    final companyName =
        _normalizeValue(offer.companyName) ??
        _normalizeValue(company?.name) ??
        'Empresa no especificada';
    final avatarUrl =
        _normalizeValue(offer.companyAvatarUrl) ??
        _normalizeValue(company?.avatarUrl);

    return JobOfferListItemViewModel(
      offerId: offer.id,
      title: offer.title,
      companyName: companyName,
      avatarUrl: avatarUrl,
      salary: offer.formattedSalary,
      modality: offer.jobType,
    );
  }

  static List<String> _mergeJobTypes({
    required List<String> existing,
    required List<JobOffer> offers,
    required String? selectedJobType,
  }) {
    final jobTypes = <String>{
      ...existing.map(_normalizeValue).whereType<String>(),
      ...offers
          .map((offer) => _normalizeValue(offer.jobType))
          .whereType<String>(),
    };
    if (selectedJobType != null) {
      jobTypes.add(selectedJobType);
    }
    final sorted = jobTypes.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  static String? _normalizeValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
