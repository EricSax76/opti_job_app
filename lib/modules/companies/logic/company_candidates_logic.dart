import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class CandidateGroup {
  const CandidateGroup({
    required this.candidateUid,
    required this.displayName,
    required this.entries,
  });

  final String candidateUid;
  final String displayName;
  final List<CandidateOfferEntry> entries;
}

class CandidateOfferEntry {
  const CandidateOfferEntry({
    required this.offerId,
    required this.offerTitle,
    required this.status,
  });

  final String offerId;
  final String offerTitle;
  final String status;
}

List<CandidateGroup> groupCandidates({
  required OfferApplicantsState applicantsState,
  required Map<String, JobOffer> offerById,
}) {
  final byCandidate = <String, List<Application>>{};
  for (final apps in applicantsState.applicants.values) {
    for (final app in apps) {
      final uid = app.candidateUid.trim();
      if (uid.isEmpty) continue;
      (byCandidate[uid] ??= []).add(app);
    }
  }

  final result = <CandidateGroup>[];
  byCandidate.forEach((candidateUid, apps) {
    apps.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    final first = apps.first;
    final displayName = (first.candidateName?.trim().isNotEmpty == true)
        ? first.candidateName!.trim()
        : (first.candidateEmail?.trim().isNotEmpty == true)
        ? first.candidateEmail!.trim()
        : candidateUid;

    final entries = <CandidateOfferEntry>[];
    final seenOffers = <String>{};
    for (final app in apps) {
      if (!seenOffers.add(app.jobOfferId)) continue;
      final offerTitle =
          offerById[app.jobOfferId]?.title ??
          app.jobOfferTitle ??
          'Oferta #${app.jobOfferId}';
      entries.add(
        CandidateOfferEntry(
          offerId: app.jobOfferId,
          offerTitle: offerTitle,
          status: app.status,
        ),
      );
    }

    result.add(
      CandidateGroup(
        candidateUid: candidateUid,
        displayName: displayName,
        entries: entries,
      ),
    );
  });

  result.sort((a, b) => a.displayName.compareTo(b.displayName));
  return result;
}
