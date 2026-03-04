import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';

class CandidateGroup {
  const CandidateGroup({
    required this.candidateUid,
    required this.displayName,
    required this.anonymizedLabel,
    required this.isAnonymousScreening,
    required this.entries,
  });

  final String candidateUid;
  final String displayName;
  final String anonymizedLabel;
  final bool isAnonymousScreening;
  final List<CandidateOfferEntry> entries;
}

class CandidateOfferEntry {
  const CandidateOfferEntry({
    required this.offerId,
    required this.offerTitle,
    required this.status,
    this.pipelineStageId,
    this.pipelineStageName,
  });

  final String offerId;
  final String offerTitle;
  final String status;
  final String? pipelineStageId;
  final String? pipelineStageName;
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
                        pipelineStageId: application.pipelineStageId,
                        pipelineStageName: application.pipelineStageName,
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

            final isAnonymousScreening = entries.every((entry) {
              return shouldAnonymizeCandidateByStage(
                status: entry.status,
                pipelineStageId: entry.pipelineStageId,
                pipelineStageName: entry.pipelineStageName,
              );
            });

            return CandidateGroup(
              candidateUid: accumulator.candidateUid,
              displayName: accumulator.displayName,
              anonymizedLabel: buildAnonymizedCandidateLabel(
                accumulator.candidateUid,
              ),
              isAnonymousScreening: isAnonymousScreening,
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
