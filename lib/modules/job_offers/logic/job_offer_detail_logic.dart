import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/models/job_offer_detail_view_model.dart';

class JobOfferDetailLogic {
  const JobOfferDetailLogic._();

  static bool shouldListenForMessages({
    required JobOfferDetailState previous,
    required JobOfferDetailState current,
  }) {
    return successMessage(previous) != successMessage(current) ||
        errorMessage(previous) != errorMessage(current) ||
        previous.matchOutcome != current.matchOutcome;
  }

  static String? successMessage(JobOfferDetailState state) {
    return _normalizeMessage(state.successMessage);
  }

  static String? errorMessage(JobOfferDetailState state) {
    return _normalizeMessage(state.errorMessage);
  }

  static JobOfferDetailViewModel buildViewModel({
    required JobOfferDetailState state,
    required bool isAuthenticated,
    required Candidate? candidate,
    required Map<int, Company> companiesById,
  }) {
    final offer = state.offer;
    final applyRequest = _buildApplyRequest(candidate: candidate, offer: offer);

    return JobOfferDetailViewModel(
      state: state,
      isAuthenticated: isAuthenticated,
      companyAvatarUrl: offer == null
          ? null
          : resolveCompanyAvatarUrl(offer: offer, companiesById: companiesById),
      applyRequest: applyRequest,
      matchRequest: _buildMatchRequest(applyRequest),
    );
  }

  static String? resolveCompanyAvatarUrl({
    required JobOffer offer,
    required Map<int, Company> companiesById,
  }) {
    final offerAvatar = _normalizeValue(offer.companyAvatarUrl);
    if (offerAvatar != null) return offerAvatar;

    final companyId = offer.companyId;
    if (companyId == null) return null;
    return _normalizeValue(companiesById[companyId]?.avatarUrl);
  }

  static JobOfferApplyRequest? _buildApplyRequest({
    required Candidate? candidate,
    required JobOffer? offer,
  }) {
    if (candidate == null || offer == null) return null;
    return JobOfferApplyRequest(candidate: candidate, offer: offer);
  }

  static JobOfferMatchRequest? _buildMatchRequest(
    JobOfferApplyRequest? applyRequest,
  ) {
    if (applyRequest == null) return null;
    final candidateUid = _normalizeValue(applyRequest.candidate.uid);
    if (candidateUid == null) return null;
    return JobOfferMatchRequest(
      candidateUid: candidateUid,
      offer: applyRequest.offer,
    );
  }

  static String? _normalizeMessage(String? message) {
    return _normalizeValue(message);
  }

  static String? _normalizeValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
