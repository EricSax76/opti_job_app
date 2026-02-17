import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:opti_job_app/modules/applicants/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

part 'company_candidates_state.dart';

class CompanyCandidatesCubit extends Cubit<CompanyCandidatesState> {
  CompanyCandidatesCubit({
    required ProfileRepository profileRepository,
    required OfferApplicantsCubit offerApplicantsCubit,
    required CompanyJobOffersCubit companyJobOffersCubit,
    required CompanyAuthCubit companyAuthCubit,
  }) : _profileRepository = profileRepository,
       _offerApplicantsCubit = offerApplicantsCubit,
       _companyJobOffersCubit = companyJobOffersCubit,
       _companyAuthCubit = companyAuthCubit,
       super(const CompanyCandidatesInitial());

  final ProfileRepository _profileRepository;
  final OfferApplicantsCubit _offerApplicantsCubit;
  final CompanyJobOffersCubit _companyJobOffersCubit;
  final CompanyAuthCubit _companyAuthCubit;

  StreamSubscription<CompanyJobOffersState>? _companyJobOffersSubscription;
  StreamSubscription<OfferApplicantsState>? _offerApplicantsSubscription;

  final Set<String> _profilesInFlight = {};
  Map<String, List<Application>>? _lastApplicantsByOffer;
  List<JobOffer>? _lastOffers;
  var _hasRequestedInitialLoad = false;
  String? _initialLoadCompanyUid;

  void initialize() {
    _companyJobOffersSubscription = _companyJobOffersCubit.stream.listen((_) {
      _syncFromExternalState();
      _maybeLoadInitialApplicants();
    });
    _offerApplicantsSubscription = _offerApplicantsCubit.stream.listen((_) {
      _syncFromExternalState();
    });

    _syncFromExternalState();
    _maybeLoadInitialApplicants();
  }

  Future<void> loadApplicantsForAllOffers({bool force = true}) async {
    final companyUid = _resolveCompanyUid();
    if (companyUid == null) return;

    final offers = _companyJobOffersCubit.state.offers;
    if (offers.isEmpty) return;

    await _offerApplicantsCubit.loadApplicantsForOffers(
      offerIds: offers.map((offer) => offer.id),
      companyUid: companyUid,
      force: force,
    );
  }

  void _maybeLoadInitialApplicants() {
    final companyUid = _resolveCompanyUid();
    if (companyUid == null) return;

    if (_initialLoadCompanyUid != companyUid) {
      _initialLoadCompanyUid = companyUid;
      _hasRequestedInitialLoad = false;
    }

    if (_hasRequestedInitialLoad) return;
    if (_companyJobOffersCubit.state.offers.isEmpty) return;

    _hasRequestedInitialLoad = true;
    unawaited(loadApplicantsForAllOffers(force: false));
  }

  String? _resolveCompanyUid() {
    final companyUid = _companyAuthCubit.state.company?.uid;
    if (companyUid == null) return null;
    final normalized = companyUid.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  void _syncFromExternalState() {
    updateData(
      applicantsByOffer: _offerApplicantsCubit.state.applicants,
      offers: _companyJobOffersCubit.state.offers,
    );
  }

  void updateData({
    required Map<String, List<Application>> applicantsByOffer,
    required List<JobOffer> offers,
  }) {
    // Basic memoization: if inputs are identical, do nothing (unless initial)
    if (identical(_lastApplicantsByOffer, applicantsByOffer) &&
        identical(_lastOffers, offers) &&
        state is! CompanyCandidatesInitial) {
      return;
    }

    _lastApplicantsByOffer = applicantsByOffer;
    _lastOffers = offers;

    final offerById = {for (final offer in offers) offer.id: offer};

    // Group candidates (synchronous logic extracted to logic file)
    final grouped = groupCandidates(
      applicantsByOffer: applicantsByOffer,
      offerById: offerById,
    );

    // Emit new state with grouped candidates
    // Preserve existing profiles
    emit(
      CompanyCandidatesLoaded(
        groupedCandidates: grouped,
        profiles: state.profiles,
        // We don't set loading purely for grouping as it's sync and fast enough usually.
        // The parent widget handles "loading" of the source data.
      ),
    );

    // Check if we need to prefetch profiles
    _checkForMissingProfiles(grouped);
  }

  void _checkForMissingProfiles(List<CandidateGroup> grouped) {
    final candidateUids = grouped
        .map((g) => g.candidateUid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet();

    if (candidateUids.isEmpty) return;

    final missingUids = candidateUids.where((uid) {
      return !state.profiles.containsKey(uid) &&
          !_profilesInFlight.contains(uid);
    }).toList();

    if (missingUids.isEmpty) return;

    _fetchProfiles(missingUids);
  }

  Future<void> _fetchProfiles(List<String> uids) async {
    _profilesInFlight.addAll(uids);

    try {
      final newProfiles = await _profileRepository.fetchCandidateProfilesByUids(
        uids,
      );
      if (isClosed) return;

      final currentProfiles = Map<String, Candidate>.from(state.profiles);
      currentProfiles.addAll(newProfiles);

      emit(
        (state as CompanyCandidatesLoaded).copyWith(profiles: currentProfiles),
      );
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
    } finally {
      _profilesInFlight.removeAll(uids);
    }
  }

  @override
  Future<void> close() async {
    await _companyJobOffersSubscription?.cancel();
    await _offerApplicantsSubscription?.cancel();
    return super.close();
  }
}
