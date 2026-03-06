import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_payload.dart';
import 'package:opti_job_app/modules/job_offers/data/services/job_offer_read_service.dart';
import 'package:opti_job_app/modules/job_offers/data/services/job_offer_write_service.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offers_page.dart';

class JobOfferRepository {
  JobOfferRepository(this._readService, this._writeService);

  final JobOfferReadService _readService;
  final JobOfferWriteService _writeService;

  Future<JobOffersPage> fetchPage({
    String? jobType,
    String? provinceId,
    String? municipalityId,
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _readService.fetchJobOffersPage(
      jobType: jobType,
      provinceId: provinceId,
      municipalityId: municipalityId,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<List<JobOffer>> fetchAll({
    String? jobType,
    String? provinceId,
    String? municipalityId,
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _readService.fetchJobOffers(
      jobType: jobType,
      provinceId: provinceId,
      municipalityId: municipalityId,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<JobOffersPage> fetchByCompanyUidPage(
    String companyUid, {
    int limit = 20,
    JobOffersPageCursor? startAfter,
  }) {
    return _readService.fetchJobOffersByCompanyUidPage(
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
    return _readService.fetchJobOffersByCompanyUid(
      companyUid,
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<JobOffer> fetchById(String id) {
    return _readService.fetchJobOffer(id);
  }

  Future<JobOffer> create(JobOfferPayload payload) async {
    final offerId = await _writeService.createJobOffer(payload);
    return _readService.fetchJobOffer(offerId);
  }
}
