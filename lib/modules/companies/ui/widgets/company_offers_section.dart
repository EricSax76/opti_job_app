import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offer_card.dart';

class CompanyOffersSection extends StatelessWidget {
  const CompanyOffersSection({super.key});

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
            'Aún no has publicado ofertas. Crea la primera para comenzar a recibir postulaciones.',
          );
        }

        return Column(
          children: [
            for (final offer in state.offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OfferCard(offer: offer),
              ),
          ],
        );
      },
    );
  }
}
