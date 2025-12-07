import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/job_offer_providers.dart';
import '../shared/widgets/app_nav_bar.dart';

class CandidateDashboardScreen extends ConsumerWidget {
  const CandidateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final offersAsync = ref.watch(jobOffersProvider(null));

    final candidateName = auth.candidate?.name ?? 'Candidato';

    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $candidateName',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Aquí tienes ofertas seleccionadas para ti.'),
            const SizedBox(height: 16),
            offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child:
                          Text('Aún no hay ofertas disponibles. Intenta más tarde.'),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(offer.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(offer.description),
                              const SizedBox(height: 4),
                              Text(
                                offer.location,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => context.go('/job-offer/${offer.id}'),
                        ),
                      );
                    },
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
      floatingActionButton: auth.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(authControllerProvider).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            )
          : null,
    );
  }
}
