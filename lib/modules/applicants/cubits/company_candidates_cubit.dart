import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:opti_job_app/modules/applicants/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

part 'company_candidates_state.dart';

class CompanyCandidatesCubit extends Cubit<CompanyCandidatesState> {
  CompanyCandidatesCubit({
    required ProfileRepository profileRepository,
  }) : _profileRepository = profileRepository,
       super(const CompanyCandidatesInitial());

  final ProfileRepository _profileRepository;
  
  // Cache to avoid re-fetching profiles in flight
  final Set<String> _profilesInFlight = {};
  
  // Cache inputs to avoid re-calculation if inputs haven't changed
  Map<String, List<Application>>? _lastApplicantsByOffer;
  List<JobOffer>? _lastOffers;

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
    emit(CompanyCandidatesLoaded(
      groupedCandidates: grouped,
      profiles: state.profiles,
      // We don't set loading purely for grouping as it's sync and fast enough usually.
      // The parent widget handles "loading" of the source data.
    ));

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
      return !state.profiles.containsKey(uid) && !_profilesInFlight.contains(uid);
    }).toList();

    if (missingUids.isEmpty) return;

    _fetchProfiles(missingUids);
  }

  Future<void> _fetchProfiles(List<String> uids) async {
    _profilesInFlight.addAll(uids);
    // Optionally emit loading state if desired, but for lazy loading profiles 
    // it's often better to just update when done to avoid flickering.
    
    try {
      final newProfiles = await _profileRepository.fetchCandidateProfilesByUids(uids);
      if (isClosed) return;
      
      final currentProfiles = Map<String, Candidate>.from(state.profiles);
      currentProfiles.addAll(newProfiles);
      
      emit((state as CompanyCandidatesLoaded).copyWith(
        profiles: currentProfiles,
      ));
    } catch (e) {
      // Log error or handle silently for profile prefetching
      debugPrint('Error fetching profiles: $e');
    } finally {
      _profilesInFlight.removeAll(uids);
    }
  }
}
