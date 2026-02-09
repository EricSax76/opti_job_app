import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';

class JobOfferRepository {
  JobOfferRepository(this._service);

  final JobOfferService _service;

  Future<JobOffersPage> fetchPage({
    String? jobType,
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _service.fetchJobOffersPage(
      jobType: jobType,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<List<JobOffer>> fetchAll({
    String? jobType,
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _service.fetchJobOffers(
      jobType: jobType,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<JobOffersPage> fetchByCompanyUidPage(
    String companyUid, {
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _service.fetchJobOffersByCompanyUidPage(
      companyUid,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<List<JobOffer>> fetchByCompanyUid(
    String companyUid, {
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _service.fetchJobOffersByCompanyUid(
      companyUid,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<JobOffer> fetchById(String id) {
    return _service.fetchJobOffer(id);
  }

  Future<JobOffer> create(JobOfferPayload payload) {
    return _service.createJobOffer(payload);
  }
}
