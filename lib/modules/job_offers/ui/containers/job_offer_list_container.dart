import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/list/job_offer_list_content.dart';

class JobOfferListContainer extends StatelessWidget {
  const JobOfferListContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobOffersCubit, JobOffersState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null &&
          current.status == JobOffersStatus.success,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<JobOffersCubit>().clearErrorMessage();
      },
      builder: (context, state) {
        final cubit = context.read<JobOffersCubit>();

        if (state.status == JobOffersStatus.initial) {
          cubit.loadOffers();
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == JobOffersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == JobOffersStatus.failure) {
          return StateMessage(
            title: 'Error',
            message: state.errorMessage ?? 'Error al cargar las ofertas.',
            actionLabel: 'Reintentar',
            onAction: () => cubit.loadOffers(forceRefresh: true),
          );
        }

        return JobOfferListContent(
          offers: state.offers,
          companiesById: state.companiesById,
          availableJobTypes: _sortedJobTypes(state),
          selectedJobType: _normalizeJobType(state.selectedJobType),
          isRefreshing: state.isRefreshing,
          isLoadingMore: state.isLoadingMore,
          hasMore: state.hasMore,
          onSelectJobType: cubit.selectJobType,
          onClearJobType: () => cubit.selectJobType(null),
          onShowAllOffers: () => cubit.selectJobType(null),
          onLoadMore: cubit.loadMoreOffers,
          onOpenOffer: (offerId) => context.push('/job-offer/$offerId'),
        );
      },
    );
  }

  List<String> _sortedJobTypes(JobOffersState state) {
    final selectedJobType = _normalizeJobType(state.selectedJobType);

    final jobTypes = <String>{
      ...state.availableJobTypes
          .map((type) => type.trim())
          .where((type) => type.isNotEmpty),
      ...state.offers
          .map((offer) => offer.jobType?.trim())
          .whereType<String>()
          .where((jobType) => jobType.isNotEmpty),
    };
    if (selectedJobType != null) {
      jobTypes.add(selectedJobType);
    }

    final sorted = jobTypes.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  String? _normalizeJobType(String? jobType) {
    if (jobType == null) return null;
    final normalized = jobType.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
