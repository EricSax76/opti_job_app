import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/candidate_card.dart';
import 'package:opti_job_app/modules/companies/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/section_message.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyCandidatesSection extends StatefulWidget {
  const CompanyCandidatesSection({super.key});

  @override
  State<CompanyCandidatesSection> createState() =>
      _CompanyCandidatesSectionState();
}

class _CompanyCandidatesSectionState extends State<CompanyCandidatesSection> {
  var _requestedInitialLoad = false;
  final Map<String, Candidate> _candidateProfilesByUid = <String, Candidate>{};
  final Set<String> _candidateProfilesInFlight = <String>{};
  Map<String, List<Application>>? _lastApplicantsByOfferRef;
  List<JobOffer>? _lastOffersRef;
  Map<String, JobOffer>? _lastOfferByIdRef;
  List<CandidateGroup> _cachedGrouped = const <CandidateGroup>[];
  Map<String, JobOffer> _cachedOfferById = const <String, JobOffer>{};

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

        final offerById = _resolveOfferById(offersState.offers);

        return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
          buildWhen: (previous, current) =>
              !identical(previous.applicants, current.applicants) ||
              !identical(previous.statuses, current.statuses),
          builder: (context, applicantsState) {
            final grouped = _resolveGroupedCandidates(
              applicantsByOffer: applicantsState.applicants,
              offerById: offerById,
            );
            _scheduleCandidateProfilesPrefetch(grouped);

            final isLoading = applicantsState.statuses.values.any(
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
                        onPressed: () => _maybeLoadAllApplicants(force: true),
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
                return CandidateCard(
                  candidate: candidate,
                  candidateProfile:
                      _candidateProfilesByUid[candidate.candidateUid.trim()],
                );
              }, childCount: separatorAwareCount),
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

    context.read<OfferApplicantsCubit>().loadApplicantsForOffers(
      offerIds: offersState.offers.map((offer) => offer.id),
      companyUid: companyUid,
      force: force,
    );

    if (!force) {
      setState(() => _requestedInitialLoad = true);
    }
  }

  List<CandidateGroup> _resolveGroupedCandidates({
    required Map<String, List<Application>> applicantsByOffer,
    required Map<String, JobOffer> offerById,
  }) {
    if (!identical(_lastApplicantsByOfferRef, applicantsByOffer) ||
        !identical(_lastOfferByIdRef, offerById)) {
      _cachedGrouped = groupCandidates(
        applicantsByOffer: applicantsByOffer,
        offerById: offerById,
      );
      _lastApplicantsByOfferRef = applicantsByOffer;
      _lastOfferByIdRef = offerById;
    }
    return _cachedGrouped;
  }

  Map<String, JobOffer> _resolveOfferById(List<JobOffer> offers) {
    if (!identical(_lastOffersRef, offers)) {
      _cachedOfferById = {for (final offer in offers) offer.id: offer};
      _lastOffersRef = offers;
    }
    return _cachedOfferById;
  }

  void _scheduleCandidateProfilesPrefetch(List<CandidateGroup> grouped) {
    final candidateUids = grouped
        .map((group) => group.candidateUid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet();
    if (candidateUids.isEmpty) return;

    final hasMissingUids = candidateUids.any(
      (uid) =>
          !_candidateProfilesByUid.containsKey(uid) &&
          !_candidateProfilesInFlight.contains(uid),
    );
    if (!hasMissingUids) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchCandidateProfiles(candidateUids);
    });
  }

  Future<void> _prefetchCandidateProfiles(Set<String> candidateUids) async {
    final missingUids = candidateUids
        .where(
          (uid) =>
              !_candidateProfilesByUid.containsKey(uid) &&
              !_candidateProfilesInFlight.contains(uid),
        )
        .toList(growable: false);
    if (missingUids.isEmpty) return;

    _candidateProfilesInFlight.addAll(missingUids);
    try {
      final profiles = await context
          .read<ProfileRepository>()
          .fetchCandidateProfilesByUids(missingUids);
      if (!mounted || profiles.isEmpty) return;
      setState(() {
        _candidateProfilesByUid.addAll(profiles);
      });
    } catch (_) {
      // Ignore profile prefetch errors: badges will remain in unknown state.
    } finally {
      _candidateProfilesInFlight.removeAll(missingUids);
    }
  }
}
