import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
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
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == CompanyJobOffersStatus.failure) {
          return SliverToBoxAdapter(
            child: SectionMessage(
              text:
                  state.errorMessage ??
                  'No se pudieron cargar tus ofertas. Intenta refrescar.',
            ),
          );
        }

        if (state.offers.isEmpty) {
          return const SliverToBoxAdapter(
            child: SectionMessage(
              text:
                  'Aún no has publicado ofertas. Crea la primera para comenzar a recibir postulaciones.',
            ),
          );
        }

        final separatorAwareCount = (state.offers.length * 2) - 1;

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index.isOdd) {
              return const SizedBox(height: 12);
            }
            final offerIndex = index ~/ 2;
            final offer = state.offers[offerIndex];
            return OfferCard(offer: offer);
          }, childCount: separatorAwareCount),
        );
      },
    );
  }
}
