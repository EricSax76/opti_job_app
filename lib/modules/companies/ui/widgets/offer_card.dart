import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offer_applicants_section.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    final resolvedCompanyUid = _companyUid(context);
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: Text(offer.title),
        subtitle: Text(
          '${offer.location} • ${offer.jobType ?? 'Tipología no especificada'}',
        ),
        leading: const Icon(Icons.work_outline),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        onExpansionChanged: (expanded) {
          if (expanded) {
            final applicantsCubit = context.read<OfferApplicantsCubit>();
            final currentStatus =
                applicantsCubit.state.statuses[offer.id] ??
                OfferApplicantsStatus.initial;
            if (currentStatus == OfferApplicantsStatus.initial ||
                currentStatus == OfferApplicantsStatus.failure) {
              final companyUid = _companyUid(context);
              if (companyUid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo determinar el usuario de empresa.',
                    ),
                  ),
                );
                return;
              }
              applicantsCubit.loadApplicants(
                offerId: offer.id,
                companyUid: companyUid,
              );
            }
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OfferApplicantsSection(
              offer: offer,
              companyUid: resolvedCompanyUid,
            ),
          ),
        ],
      ),
    );
  }

  String? _companyUid(BuildContext context) {
    return offer.companyUid ??
        context.read<CompanyAuthCubit>().state.company?.uid;
  }
}
