import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/offer_card_view_model.dart';

class OfferCardLogic {
  const OfferCardLogic._();

  static OfferCardViewModel buildViewModel({
    required JobOffer offer,
    required String? companyUidFromAuth,
    required String? avatarUrlFromAuth,
  }) {
    final jobType =
        _normalizeValue(offer.jobType) ?? 'Tipología no especificada';
    return OfferCardViewModel(
      subtitle: '${offer.location} • $jobType',
      companyUid: normalizeCompanyUid(offer.companyUid ?? companyUidFromAuth),
      avatarUrl: _normalizeValue(avatarUrlFromAuth),
    );
  }

  static bool shouldLoadApplicants({
    required bool expanded,
    required OfferApplicantsStatus status,
  }) {
    if (!expanded) return false;
    return status == OfferApplicantsStatus.initial ||
        status == OfferApplicantsStatus.failure;
  }

  static String? normalizeCompanyUid(String? uid) {
    return _normalizeValue(uid);
  }

  static String? _normalizeValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
