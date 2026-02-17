import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';

class OfferApplicantsSectionViewModel {
  const OfferApplicantsSectionViewModel({
    required this.status,
    required this.applicants,
    required this.errorMessage,
  });

  final OfferApplicantsStatus status;
  final List<Application> applicants;
  final String? errorMessage;
}
