import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_header.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/create_offer_card.dart';

class CompanyOfferCreationContent extends StatelessWidget {
  const CompanyOfferCreationContent({
    super.key,
    this.companyName,
    required this.formKey,
    required this.formControllers,
    required this.isGeneratingOffer,
    required this.onSubmit,
    required this.onGenerateWithAi,
  });

  final String? companyName;
  final GlobalKey<FormState> formKey;
  final OfferFormControllers formControllers;
  final bool isGeneratingOffer;
  final VoidCallback onSubmit;
  final VoidCallback onGenerateWithAi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        if (companyName != null)
          CompanyDashboardHeader(companyName: companyName!),
        const SizedBox(height: 24),
        CreateOfferCard(
          formKey: formKey,
          controllers: formControllers,
          onSubmit: onSubmit,
          onGenerateWithAi: onGenerateWithAi,
          isGenerating: isGeneratingOffer,
        ),
      ],
    );
  }
}
