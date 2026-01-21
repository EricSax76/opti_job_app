import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_card.dart';
import 'package:opti_job_app/modules/companies/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/section_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class CompanyCandidatesSection extends StatefulWidget {
  const CompanyCandidatesSection({super.key});

  @override
  State<CompanyCandidatesSection> createState() =>
      _CompanyCandidatesSectionState();
}

class _CompanyCandidatesSectionState extends State<CompanyCandidatesSection> {
  var _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadAllApplicants();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, offersState) {
        if (offersState.status == CompanyJobOffersStatus.loading ||
            offersState.status == CompanyJobOffersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (offersState.status == CompanyJobOffersStatus.failure) {
          return SectionMessage(
            text:
                offersState.errorMessage ??
                'No se pudieron cargar tus ofertas. Intenta refrescar.',
          );
        }

        if (offersState.offers.isEmpty) {
          return const SectionMessage(
            text:
                'Aún no hay ofertas publicadas. Publica una oferta para recibir candidatos.',
          );
        }

        final offerById = {
          for (final offer in offersState.offers) offer.id: offer,
        };

        return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
          builder: (context, applicantsState) {
            final grouped = groupCandidates(
              applicantsState: applicantsState,
              offerById: offerById,
            );

            final isLoading = applicantsState.statuses.values.any(
              (s) => s == OfferApplicantsStatus.loading,
            );

            if (isLoading && grouped.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (grouped.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionMessage(
                    text:
                        'Aún no hay candidatos cargados. Pulsa para cargar postulaciones de tus ofertas.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _maybeLoadAllApplicants(force: true),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Cargar candidatos'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                for (final candidate in grouped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CandidateCard(candidate: candidate),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _maybeLoadAllApplicants({bool force = false}) {
    if (_requestedInitialLoad && !force) return;

    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;
    final offersState = context.read<CompanyJobOffersCubit>().state;
    if (offersState.offers.isEmpty) return;

    final applicantsCubit = context.read<OfferApplicantsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final offer in offersState.offers) {
        final status =
            applicantsCubit.state.statuses[offer.id] ??
            OfferApplicantsStatus.initial;
        if (force ||
            status == OfferApplicantsStatus.initial ||
            status == OfferApplicantsStatus.failure) {
          applicantsCubit.loadApplicants(
            offerId: offer.id,
            companyUid: companyUid,
          );
        }
      }
    });

    if (!force) {
      setState(() => _requestedInitialLoad = true);
    }
  }
}
