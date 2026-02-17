import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferApplyRequest {
  const JobOfferApplyRequest({required this.candidate, required this.offer});

  final Candidate candidate;
  final JobOffer offer;
}

class JobOfferMatchRequest {
  const JobOfferMatchRequest({required this.candidateUid, required this.offer});

  final String candidateUid;
  final JobOffer offer;
}

class JobOfferDetailViewModel {
  const JobOfferDetailViewModel({
    required this.state,
    required this.isAuthenticated,
    required this.companyAvatarUrl,
    required this.applyRequest,
    required this.matchRequest,
  });

  final JobOfferDetailState state;
  final bool isAuthenticated;
  final String? companyAvatarUrl;
  final JobOfferApplyRequest? applyRequest;
  final JobOfferMatchRequest? matchRequest;
}
