import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/models/company_offer_creation_view_model.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';

class CompanyOfferCreationLogic {
  const CompanyOfferCreationLogic._();

  static CompanyOfferCreationViewModel buildViewModel({
    required String? companyName,
    required bool isGeneratingOffer,
  }) {
    return CompanyOfferCreationViewModel(
      companyName: companyName,
      isGeneratingOffer: isGeneratingOffer,
    );
  }

  static bool shouldResetFormOnStatusChange(
    JobOfferFormState previous,
    JobOfferFormState current,
  ) {
    return previous.status != current.status &&
        current.status == JobOfferFormStatus.success;
  }

  static JobOfferPayload? buildSubmitPayload({
    required GlobalKey<FormState> formKey,
    required OfferFormControllers formControllers,
    required Company? company,
  }) {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate() || company == null) {
      return null;
    }

    final jobType = formControllers.jobType.text.trim();
    final salaryMin = formControllers.salaryMin.text.trim();
    final salaryMax = formControllers.salaryMax.text.trim();
    final education = formControllers.education.text.trim();
    final keyIndicators = formControllers.keyIndicators.text.trim();

    return JobOfferPayload(
      title: formControllers.title.text.trim(),
      description: formControllers.description.text.trim(),
      location: formControllers.location.text.trim(),
      companyId: company.id,
      companyUid: company.uid,
      companyName: company.name,
      companyAvatarUrl: company.avatarUrl,
      jobType: jobType.isEmpty ? null : jobType,
      salaryMin: salaryMin.isEmpty ? null : salaryMin,
      salaryMax: salaryMax.isEmpty ? null : salaryMax,
      education: education.isEmpty ? null : education,
      keyIndicators: keyIndicators.isEmpty ? null : keyIndicators,
    );
  }
}
