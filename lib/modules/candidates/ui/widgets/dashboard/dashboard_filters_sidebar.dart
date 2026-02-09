import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';

class DashboardFiltersSidebar extends StatelessWidget {
  const DashboardFiltersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
      selector: (state) => state.activeFilters,
      builder: (context, filters) {
        return JobOfferFilterSidebar(
          currentFilters: filters,
          onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
        );
      },
    );
  }
}
