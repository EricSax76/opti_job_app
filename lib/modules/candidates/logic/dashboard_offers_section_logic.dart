import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/models/dashboard_offers_section_view_model.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';

class DashboardOffersSectionLogic {
  const DashboardOffersSectionLogic._();

  static bool shouldRebuild(JobOffersState previous, JobOffersState current) {
    return previous.status != current.status ||
        previous.offers != current.offers ||
        previous.filteredOffers != current.filteredOffers ||
        previous.companiesById != current.companiesById ||
        previous.errorMessage != current.errorMessage ||
        previous.activeFilters != current.activeFilters ||
        previous.isLoadingMore != current.isLoadingMore;
  }

  static Set<String> resolveAppliedOfferIds(MyApplicationsState state) {
    return state.applications
        .map((entry) => entry.application.jobOfferId)
        .toSet();
  }

  static DashboardOffersSectionViewModel buildViewModel({
    required JobOffersState state,
    required Set<String> appliedOfferIds,
  }) {
    final offers = state.displayedOffers
        .where((offer) => !appliedOfferIds.contains(offer.id))
        .toList(growable: false);

    return DashboardOffersSectionViewModel(
      status: state.status.name,
      offers: offers,
      companiesById: state.companiesById,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      hasActiveFilters: state.activeFilters.hasActiveFilters,
      errorMessage: state.errorMessage,
    );
  }
}
