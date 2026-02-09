import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_summary_card.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';

const double _paginationThreshold = 280;

class JobOfferListScreen extends StatelessWidget {
  const JobOfferListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: BlocConsumer<JobOffersCubit, JobOffersState>(
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
          if (state.status == JobOffersStatus.initial) {
            context.read<JobOffersCubit>().loadOffers();
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
              onAction: () =>
                  context.read<JobOffersCubit>().loadOffers(forceRefresh: true),
            );
          }

          final offers = state.offers;
          final selectedJobType = state.selectedJobType?.trim();
          final jobTypes = <String>{
            ...state.availableJobTypes,
            ...offers
                .map((offer) => offer.jobType?.trim())
                .whereType<String>()
                .where((jobType) => jobType.isNotEmpty),
          };
          if (selectedJobType != null && selectedJobType.isNotEmpty) {
            jobTypes.add(selectedJobType);
          }
          final sortedJobTypes = jobTypes.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) return false;
              final pixels = notification.metrics.pixels;
              final max = notification.metrics.maxScrollExtent;
              if (max - pixels <= _paginationThreshold &&
                  state.hasMore &&
                  !state.isLoadingMore &&
                  !state.isRefreshing &&
                  state.status == JobOffersStatus.success) {
                context.read<JobOffersCubit>().loadMoreOffers();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(uiSpacing16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Ofertas activas',
                          subtitle: 'Encuentra tu próximo reto profesional.',
                        ),
                        const SizedBox(height: uiSpacing20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                initialValue: selectedJobType,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar por tipología',
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Todas'),
                                  ),
                                  ...sortedJobTypes.map(
                                    (type) => DropdownMenuItem<String?>(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => context
                                    .read<JobOffersCubit>()
                                    .selectJobType(value),
                              ),
                            ),
                            if (state.selectedJobType != null) ...[
                              const SizedBox(width: uiSpacing12),
                              IconButton.filledTonal(
                                onPressed: () => context
                                    .read<JobOffersCubit>()
                                    .selectJobType(null),
                                icon: const Icon(Icons.close),
                                tooltip: 'Limpiar filtro',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.isRefreshing)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        uiSpacing16,
                        0,
                        uiSpacing16,
                        uiSpacing12,
                      ),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ),
                if (offers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: StateMessage(
                        title: 'Sin resultados',
                        message: 'No hay ofertas disponibles que coincidan.',
                        actionLabel: 'Ver todas',
                        onAction: () =>
                            context.read<JobOffersCubit>().selectJobType(null),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      uiSpacing16,
                      0,
                      uiSpacing16,
                      uiSpacing24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final offer = offers[index];
                        final company = offer.companyId == null
                            ? null
                            : state.companiesById[offer.companyId!];
                        final companyName =
                            offer.companyName ??
                            company?.name ??
                            'Empresa no especificada';
                        final avatarUrl =
                            offer.companyAvatarUrl ?? company?.avatarUrl;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: uiSpacing12),
                          child: JobOfferSummaryCard(
                            title: offer.title,
                            company: companyName,
                            avatarUrl: avatarUrl,
                            salary: offer.formattedSalary,
                            modality: offer.jobType,
                            onTap: () => context.push('/job-offer/${offer.id}'),
                          ),
                        );
                      }, childCount: offers.length),
                    ),
                  ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: uiSpacing20),
                      child: Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
