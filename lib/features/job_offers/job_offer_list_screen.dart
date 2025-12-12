import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:infojobs_flutter_app/providers/job_offer_providers.dart';
import 'package:infojobs_flutter_app/features/shared/widgets/app_nav_bar.dart';

class JobOfferListScreen extends ConsumerStatefulWidget {
  const JobOfferListScreen({super.key});

  @override
  ConsumerState<JobOfferListScreen> createState() =>
      _JobOfferListScreenState();
}

class _JobOfferListScreenState
    extends ConsumerState<JobOfferListScreen> {
  String? _selectedJobType;

  @override
  Widget build(BuildContext context) {
    final jobOffersAsync =
        ref.watch(jobOffersProvider(_selectedJobType));

    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertas activas',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Encuentra tu próximo reto profesional.'),
            const SizedBox(height: 16),
            jobOffersAsync.when(
              data: (offers) {
                final jobTypes = offers
                    .map((offer) => offer.jobType)
                    .whereType<String>()
                    .where((jobType) => jobType.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _selectedJobType,
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
                              onChanged: (value) {
                                setState(() {
                                  _selectedJobType = value;
                                });
                              },
                            ),
                          ),
                          if (_selectedJobType != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedJobType = null;
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (offers.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No hay ofertas disponibles.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: offers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final offer = offers[index];
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      if (offer.salaryMin != null ||
                                          offer.salaryMax != null)
                                        Text(
                                          'Salario: ${offer.salaryMin ?? 'N/D'}'
                                          '${offer.salaryMax != null ? ' - ${offer.salaryMax}' : ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.go(
                                    '/job-offer/${offer.id}',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Expanded(
                child: Center(
                  child: Text('Error al cargar ofertas: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
