import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class CandidateApplicationEntry {
  const CandidateApplicationEntry({
    required this.application,
    this.offer,
  });

  final Application application;
  final JobOffer? offer;
}
