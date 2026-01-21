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

class JobOfferListScreen extends StatelessWidget {
  const JobOfferListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: BlocBuilder<JobOffersCubit, JobOffersState>(
        builder: (context, state) {
          if (state.status == JobOffersStatus.loading ||
              state.status == JobOffersStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == JobOffersStatus.failure) {
            return StateMessage(
              title: 'Error',
              message: state.errorMessage ?? 'Error al cargar las ofertas.',
              actionLabel: 'Reintentar',
              onAction: () => context.read<JobOffersCubit>().loadOffers(),
            );
          }

          final jobTypes = state.offers
              .map((offer) => offer.jobType)
              .whereType<String>()
              .where((jobType) => jobType.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          return CustomScrollView(
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
                              initialValue: state.selectedJobType,
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por tipología',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todas'),
                                ),
                                ...jobTypes.map(
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
              if (state.offers.isEmpty)
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
                      uiSpacing16, 0, uiSpacing16, uiSpacing24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final offer = state.offers[index];
                        final company = offer.companyId == null
                            ? null
                            : state.companiesById[offer.companyId!];
                        final companyName = offer.companyName ??
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
                      },
                      childCount: state.offers.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
