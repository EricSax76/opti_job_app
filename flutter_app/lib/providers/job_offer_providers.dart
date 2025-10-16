import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/job_offer.dart';
import 'package:infojobs_flutter_app/data/repositories/job_offer_repository.dart';

final jobOffersProvider = FutureProvider.autoDispose
    .family<List<JobOffer>, String?>((ref, seniority) async {
  final repository = ref.watch(jobOfferRepositoryProvider);
  return repository.fetchAll(query: seniority);
});

final jobOfferDetailProvider =
    FutureProvider.autoDispose.family<JobOffer, String>((ref, id) {
  final repository = ref.watch(jobOfferRepositoryProvider);
  return repository.fetchById(id);
});
