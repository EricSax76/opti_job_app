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
  required Map<String, List<Application>> applicantsByOffer,
  required Map<String, JobOffer> offerById,
}) {
  final byCandidate = <String, _CandidateAccumulator>{};
  for (final apps in applicantsByOffer.values) {
    for (final app in apps) {
      final candidateUid = app.candidateUid.trim();
      if (candidateUid.isEmpty) continue;

      final accumulator = byCandidate.putIfAbsent(
        candidateUid,
        () => _CandidateAccumulator(candidateUid: candidateUid),
      );
      accumulator.registerApplication(app);
    }
  }

  final result =
      byCandidate.values
          .map((accumulator) {
            final entries =
                accumulator.latestByOffer.values
                    .map((application) {
                      final offerTitle =
                          offerById[application.jobOfferId]?.title ??
                          application.jobOfferTitle ??
                          'Oferta #${application.jobOfferId}';
                      return CandidateOfferEntry(
                        offerId: application.jobOfferId,
                        offerTitle: offerTitle,
                        status: application.status,
                      );
                    })
                    .toList(growable: false)
                  ..sort((a, b) {
                    final aDate =
                        accumulator.latestByOffer[a.offerId]?.updatedAt ??
                        accumulator.latestByOffer[a.offerId]?.createdAt;
                    final bDate =
                        accumulator.latestByOffer[b.offerId]?.updatedAt ??
                        accumulator.latestByOffer[b.offerId]?.createdAt;
                    if (aDate == null && bDate == null) return 0;
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;
                    return bDate.compareTo(aDate);
                  });

            return CandidateGroup(
              candidateUid: accumulator.candidateUid,
              displayName: accumulator.displayName,
              entries: entries,
            );
          })
          .toList(growable: false)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  return result;
}

class _CandidateAccumulator {
  _CandidateAccumulator({required this.candidateUid})
    : displayName = candidateUid;

  final String candidateUid;
  String displayName;
  final Map<String, Application> latestByOffer = <String, Application>{};

  void registerApplication(Application application) {
    final candidateName = application.candidateName?.trim();
    if (candidateName != null && candidateName.isNotEmpty) {
      displayName = candidateName;
    } else if (displayName == candidateUid) {
      final candidateEmail = application.candidateEmail?.trim();
      if (candidateEmail != null && candidateEmail.isNotEmpty) {
        displayName = candidateEmail;
      }
    }

    final offerId = application.jobOfferId.trim();
    if (offerId.isEmpty) return;

    final previous = latestByOffer[offerId];
    if (previous == null || _isAfter(application, previous)) {
      latestByOffer[offerId] = application;
    }
  }

  bool _isAfter(Application current, Application previous) {
    final currentDate = current.updatedAt ?? current.createdAt;
    final previousDate = previous.updatedAt ?? previous.createdAt;
    if (currentDate == null) return false;
    if (previousDate == null) return true;
    return currentDate.isAfter(previousDate);
  }
}
