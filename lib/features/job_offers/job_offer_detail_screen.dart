import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/providers/job_offer_providers.dart';
import 'package:infojobs_flutter_app/features/shared/widgets/app_nav_bar.dart';

class JobOfferDetailScreen extends ConsumerWidget {
  const JobOfferDetailScreen({super.key, required this.offerId});

  final int offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerAsync = ref.watch(jobOfferDetailProvider(offerId));

    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: offerAsync.when(
          data: (offer) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(offer.location),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.description),
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Tipología',
                        value: offer.jobType ?? 'No especificada',
                      ),
                      _InfoRow(
                        label: 'Educación requerida',
                        value: offer.education ?? 'No especificada',
                      ),
                      if (offer.salaryMin != null || offer.salaryMax != null)
                        _InfoRow(
                          label: 'Salario',
                          value: '${offer.salaryMin ?? 'N/D'}'
                              '${offer.salaryMax != null ? ' - ${offer.salaryMax}' : ''}',
                        ),
                      if (offer.keyIndicators != null)
                        _InfoRow(
                          label: 'Indicadores clave',
                          value: offer.keyIndicators!,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Postularme'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('No se pudo cargar la oferta: $error'),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
