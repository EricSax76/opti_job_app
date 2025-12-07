import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job_offer.dart';
import '../data/repositories/job_offer_repository.dart';

final jobOffersProvider = FutureProvider.autoDispose
    .family<List<JobOffer>, String?>((ref, jobType) async {
  final repository = ref.watch(jobOfferRepositoryProvider);
  return repository.fetchAll(jobType: jobType);
});

final jobOfferDetailProvider =
    FutureProvider.autoDispose.family<JobOffer, int>((ref, id) {
  final repository = ref.watch(jobOfferRepositoryProvider);
  return repository.fetchById(id);
});
