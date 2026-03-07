import 'package:opti_job_app/modules/applicants/ui/models/dashboard_candidates_card_view_model.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';

class DashboardCandidatesCardLogic {
  const DashboardCandidatesCardLogic._();

  static DashboardCandidatesCardViewModel buildViewModel(
    OfferApplicantsState state,
  ) {
    final byUid = <String, DashboardCandidateSummaryViewModel>{};
    for (final applications in state.applicants.values) {
      for (final application in applications) {
        final uid = application.candidateUid.trim();
        if (uid.isEmpty || byUid.containsKey(uid)) continue;

        final displayName = shouldAnonymizeApplication(application)
            ? buildAnonymizedCandidateLabel(
                uid,
                anonymizedLabel: application.anonymizedLabel,
              )
            : (application.candidateName?.trim().isNotEmpty == true)
            ? application.candidateName!.trim()
            : (application.candidateEmail?.trim().isNotEmpty == true)
            ? application.candidateEmail!.trim()
            : uid;

        byUid[uid] = DashboardCandidateSummaryViewModel(
          candidateUid: uid,
          displayName: displayName,
          offerId: application.jobOfferId,
          applicationId: (application.id ?? '').trim(),
          isAnonymized: shouldAnonymizeApplication(application),
        );
      }
    }

    final isLoading = state.statuses.values.any(
      (status) => status == OfferApplicantsStatus.loading,
    );

    return DashboardCandidatesCardViewModel(
      candidates: byUid.values.toList(growable: false),
      isLoading: isLoading,
    );
  }
}
