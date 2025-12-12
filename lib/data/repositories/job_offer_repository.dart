import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/job_offer.dart';
import 'package:infojobs_flutter_app/data/services/job_offer_service.dart';

final jobOfferRepositoryProvider = Provider<JobOfferRepository>((ref) {
  final service = ref.watch(jobOfferServiceProvider);
  return JobOfferRepository(service);
});

class JobOfferRepository {
  JobOfferRepository(this._service);

  final JobOfferService _service;

  Future<List<JobOffer>> fetchAll({String? jobType}) {
    return _service.fetchJobOffers(jobType: jobType);
  }

  Future<JobOffer> fetchById(int id) {
    return _service.fetchJobOffer(id);
  }

  Future<JobOffer> create(JobOfferPayload payload) {
    return _service.createJobOffer(payload);
  }
}
