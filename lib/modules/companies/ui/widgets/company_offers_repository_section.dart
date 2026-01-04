import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class CompanyOffersRepositorySection extends StatelessWidget {
  const CompanyOffersRepositorySection({super.key});

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const muted = Color(0xFF475569);

    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, state) {
        if (state.status == CompanyJobOffersStatus.loading ||
            state.status == CompanyJobOffersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        Widget message(String text) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Text(
              text,
              style: const TextStyle(color: muted, height: 1.4),
            ),
          );
        }

        if (state.status == CompanyJobOffersStatus.failure) {
          return message(
            state.errorMessage ??
                'No se pudieron cargar tus ofertas. Intenta refrescar.',
          );
        }

        if (state.offers.isEmpty) {
          return message(
            'Aún no has publicado ofertas. Ve a "Publicar oferta" para crear la primera.',
          );
        }

        return Column(
          children: [
            for (final offer in state.offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferRepositoryCard(offer: offer),
              ),
          ],
        );
      },
    );
  }
}

class _OfferRepositoryCard extends StatelessWidget {
  const _OfferRepositoryCard({required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);
    const background = Color(0xFFF8FAFC);
    final avatarUrl = context.watch<CompanyAuthCubit>().state.company?.avatarUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: background,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.business_outlined, color: muted)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${offer.location} • ${offer.jobType ?? 'Tipología no especificada'}',
                  style: const TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
