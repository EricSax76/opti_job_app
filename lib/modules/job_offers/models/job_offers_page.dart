import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOffersPageCursor {
  const JobOffersPageCursor(this.snapshot);

  final QueryDocumentSnapshot<Map<String, dynamic>> snapshot;
}

class JobOffersPage {
  const JobOffersPage({
    required this.offers,
    required this.hasMore,
    required this.nextPageCursor,
  });

  final List<JobOffer> offers;
  final bool hasMore;
  final JobOffersPageCursor? nextPageCursor;
}
