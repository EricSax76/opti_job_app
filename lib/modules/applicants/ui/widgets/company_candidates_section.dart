import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/applicants/cubits/company_candidates_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/candidate_card.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/section_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyCandidatesSection extends StatelessWidget {
  const CompanyCandidatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompanyCandidatesCubit(
        profileRepository: context.read<ProfileRepository>(),
      ),
      child: const _CompanyCandidatesContent(),
    );
  }
}

class _CompanyCandidatesContent extends StatefulWidget {
  const _CompanyCandidatesContent();

  @override
  State<_CompanyCandidatesContent> createState() =>
      _CompanyCandidatesContentState();
}

class _CompanyCandidatesContentState extends State<_CompanyCandidatesContent> {
  var _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadAllApplicants();
  }

  void _maybeLoadAllApplicants({bool force = false}) {
    if (_requestedInitialLoad && !force) return;

    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;
    final offersState = context.read<CompanyJobOffersCubit>().state;
    if (offersState.offers.isEmpty) return;

    context.read<OfferApplicantsCubit>().loadApplicantsForOffers(
          offerIds: offersState.offers.map((offer) => offer.id),
          companyUid: companyUid,
          force: force,
        );

    if (!force) {
      setState(() => _requestedInitialLoad = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CompanyJobOffersCubit, CompanyJobOffersState>(
          listener: (context, offersState) {
            final applicantsState = context.read<OfferApplicantsCubit>().state;
            context.read<CompanyCandidatesCubit>().updateData(
                  applicantsByOffer: applicantsState.applicants,
                  offers: offersState.offers,
                );
          },
        ),
        BlocListener<OfferApplicantsCubit, OfferApplicantsState>(
          listener: (context, applicantsState) {
            final offersState = context.read<CompanyJobOffersCubit>().state;
            context.read<CompanyCandidatesCubit>().updateData(
                  applicantsByOffer: applicantsState.applicants,
                  offers: offersState.offers,
                );
          },
        ),
      ],
      child: BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
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
                text: offersState.errorMessage ??
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

              return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
                builder: (context, applicantsState) {
                  final isLoading =applicantsState.statuses.values.any(
                    (s) => s == OfferApplicantsStatus.loading,
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _maybeLoadAllApplicants(force: true),
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
                        return const SizedBox(height: 12);
                      }

                      final groupIndex = index ~/ 2;
                      final candidate = grouped[groupIndex];
                      final profile =
                          candidatesState.profiles[candidate.candidateUid.trim()];
                      
                      return CandidateCard(
                        candidate: candidate,
                        candidateProfile: profile,
                      );
                    }, childCount: separatorAwareCount),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
