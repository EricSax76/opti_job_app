import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/job_offers/cubit/job_offers_cubit.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';

class JobOfferListScreen extends StatelessWidget {
  const JobOfferListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertas activas',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Encuentra tu próximo reto profesional.'),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<JobOffersCubit, JobOffersState>(
                builder: (context, state) {
                  if (state.status == JobOffersStatus.loading ||
                      state.status == JobOffersStatus.initial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == JobOffersStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage ?? 'Error al cargar las ofertas.',
                      ),
                    );
                  }

                  final jobTypes =
                      state.offers
                          .map((offer) => offer.jobType)
                          .whereType<String>()
                          .where((jobType) => jobType.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();

                  return Column(
                    children: [
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
                          if (state.selectedJobType != null)
                            TextButton(
                              onPressed: () => context
                                  .read<JobOffersCubit>()
                                  .selectJobType(null),
                              child: const Text('Limpiar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.offers.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No hay ofertas disponibles.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.offers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final offer = state.offers[index];
                              return Card(
                                elevation: 1,
                                child: ListTile(
                                  title: Text(offer.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(offer.description),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${offer.location} · ${offer.jobType ?? 'Tipología no especificada'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      if (offer.salaryMin != null ||
                                          offer.salaryMax != null)
                                        Text(
                                          'Salario: ${offer.salaryMin ?? 'N/D'}'
                                          '${offer.salaryMax != null ? ' - ${offer.salaryMax}' : ''}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.go('/job-offer/${offer.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
