import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/offer_card.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/section_message.dart';

class CompanyOffersSection extends StatelessWidget {
  const CompanyOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, state) {
        if (state.status == CompanyJobOffersStatus.loading ||
            state.status == CompanyJobOffersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == CompanyJobOffersStatus.failure) {
          return SectionMessage(
            text: state.errorMessage ??
                'No se pudieron cargar tus ofertas. Intenta refrescar.',
          );
        }

        if (state.offers.isEmpty) {
          return const SectionMessage(
            text:
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
