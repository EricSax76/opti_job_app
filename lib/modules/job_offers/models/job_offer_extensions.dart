import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

extension JobOfferFormatting on JobOffer {
  String? get formattedSalary {
    final min = salaryMin?.trim();
    final max = salaryMax?.trim();

    final hasMin = min != null && min.isNotEmpty;
    final hasMax = max != null && max.isNotEmpty;

    if (hasMin && hasMax) return '$min - $max';
    if (hasMin) return 'Desde $min';
    if (hasMax) return 'Hasta $max';
    return null;
  }
}
