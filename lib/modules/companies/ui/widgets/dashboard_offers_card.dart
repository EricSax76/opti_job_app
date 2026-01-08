import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class DashboardOffersCard extends StatelessWidget {
  const DashboardOffersCard({super.key, required this.onLoadCandidates});

  final VoidCallback onLoadCandidates;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
        builder: (context, state) {
          if (state.status == CompanyJobOffersStatus.loading ||
              state.status == CompanyJobOffersStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = state.offers;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFERTAS PUBLICADAS',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${offers.length}',
                style: const TextStyle(
                  color: ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (offers.isEmpty)
                const Text(
                  'Aún no has publicado ofertas.',
                  style: TextStyle(color: muted, height: 1.4),
                )
              else
                Column(
                  children: [
                    for (final offer in offers.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OfferRow(offer: offer),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onLoadCandidates,
                  icon: const Icon(Icons.refresh_outlined, size: 18),
                  label: const Text('Actualizar candidatos'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.work_outline, color: ink, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                offer.location,
                style: const TextStyle(color: muted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
