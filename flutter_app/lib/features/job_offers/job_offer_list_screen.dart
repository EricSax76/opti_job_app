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
  String? _selectedSeniority;
  final _seniorityFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    final jobOffersAsync =
        ref.watch(jobOffersProvider(_selectedSeniority));

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
                final seniorities = offers
                    .map((offer) => offer.seniority)
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: _seniorityFieldKey,
                              initialValue: _selectedSeniority ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por seniority',
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Todas'),
                                ),
                                ...seniorities.map(
                                  (seniority) => DropdownMenuItem<String>(
                                    value: seniority,
                                    child: Text(seniority),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSeniority =
                                      (value == null || value.isEmpty)
                                          ? null
                                          : value;
                                });
                              },
                            ),
                          ),
                          if (_selectedSeniority != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSeniority = null;
                                  _seniorityFieldKey.currentState?.reset();
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
                                        '${offer.location} · ${offer.seniority}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      if (offer.skills.isNotEmpty)
                                        Wrap(
                                          spacing: 4,
                                          children: offer.skills
                                              .take(5)
                                              .map(
                                                (skill) => Chip(
                                                  label: Text(skill),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                              )
                                              .toList(),
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
