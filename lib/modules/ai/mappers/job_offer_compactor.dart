import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferCompactor {
  const JobOfferCompactor();

  Map<String, dynamic> compact(JobOffer offer) {
    String truncate(String value, int max) =>
        value.length <= max ? value : value.substring(0, max);

    return <String, dynamic>{
      'id': offer.id,
      'title': truncate(offer.title.trim(), 140),
      'location': truncate(offer.location.trim(), 120),
      'description': truncate(offer.description.trim(), 1600),
      if (offer.jobType != null)
        'job_type': truncate(offer.jobType!.trim(), 60),
      if (offer.education != null)
        'education': truncate(offer.education!.trim(), 120),
      if (offer.keyIndicators != null)
        'key_indicators': truncate(offer.keyIndicators!.trim(), 600),
      if (offer.salaryMin != null) 'salary_min': offer.salaryMin,
      if (offer.salaryMax != null) 'salary_max': offer.salaryMax,
    };
  }
}
