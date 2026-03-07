import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/cubits/company_candidates_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/candidate_card.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/section_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class CompanyCandidatesSection extends StatelessWidget {
  const CompanyCandidatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, offersState) {
        if (offersState.status == CompanyJobOffersStatus.loading ||
            offersState.status == CompanyJobOffersStatus.initial) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (offersState.status == CompanyJobOffersStatus.failure) {
          return SliverToBoxAdapter(
            child: SectionMessage(
              text:
                  offersState.errorMessage ??
                  'No se pudieron cargar tus ofertas. Intenta refrescar.',
            ),
          );
        }

        if (offersState.offers.isEmpty) {
          return const SliverToBoxAdapter(
            child: SectionMessage(
              text:
                  'Aún no hay ofertas publicadas. Publica una oferta para recibir candidatos.',
            ),
          );
        }

        return BlocBuilder<CompanyCandidatesCubit, CompanyCandidatesState>(
          builder: (context, candidatesState) {
            final grouped = candidatesState.groupedCandidates;
            final isLoading = context.select<OfferApplicantsCubit, bool>(
              (cubit) => cubit.state.statuses.values.any(
                (status) => status == OfferApplicantsStatus.loading,
              ),
            );

            if (isLoading && grouped.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (grouped.isEmpty) {
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionMessage(
                      text:
                          'Aún no hay candidatos cargados. Pulsa para cargar postulaciones de tus ofertas.',
                    ),
                    const SizedBox(height: uiSpacing8 + 2),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<CompanyCandidatesCubit>()
                              .loadApplicantsForAllOffers(force: true);
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Cargar candidatos'),
                      ),
                    ),
                  ],
                ),
              );
            }

            final separatorAwareCount = (grouped.length * 2) - 1;

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return const SizedBox(height: uiSpacing12);
                }

                final groupIndex = index ~/ 2;
                final candidate = grouped[groupIndex];

                return CandidateCard(candidate: candidate);
              }, childCount: separatorAwareCount),
            );
          },
        );
      },
    );
  }
}
