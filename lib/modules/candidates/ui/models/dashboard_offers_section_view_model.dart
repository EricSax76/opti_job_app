import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class DashboardOffersSectionViewModel {
  const DashboardOffersSectionViewModel({
    required this.status,
    required this.offers,
    required this.companiesById,
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasActiveFilters,
    required this.errorMessage,
  });

  final String status;
  final List<JobOffer> offers;
  final Map<int, dynamic> companiesById;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasActiveFilters;
  final String? errorMessage;
}
