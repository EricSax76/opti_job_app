import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/applicant_tile.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class OfferApplicantsSection extends StatelessWidget {
  const OfferApplicantsSection({
    super.key,
    required this.offer,
    required this.companyUid,
  });

  final JobOffer offer;
  final String? companyUid;

  @override
  Widget build(BuildContext context) {
    final resolvedCompanyUid = companyUid;
    if (resolvedCompanyUid == null) {
      return const Text(
        'No se pudieron cargar los aplicantes porque falta el identificador de empresa.',
      );
    }
    return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
      buildWhen: (previous, current) {
        final prevStatus =
            previous.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final currentStatus =
            current.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final prevApplicants = previous.applicants[offer.id];
        final currentApplicants = current.applicants[offer.id];
        final prevError = previous.errors[offer.id];
        final currentError = current.errors[offer.id];
        return prevStatus != currentStatus ||
            prevApplicants != currentApplicants ||
            prevError != currentError;
      },
      builder: (context, state) {
        final status =
            state.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final applicants = state.applicants[offer.id] ?? const <Application>[];
        final error = state.errors[offer.id];

        switch (status) {
          case OfferApplicantsStatus.initial:
            return const Text(
              'Expande la tarjeta para cargar los aplicantes de esta oferta.',
            );
          case OfferApplicantsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          case OfferApplicantsStatus.failure:
            return Text(error ?? 'No se pudieron cargar los aplicantes.');
          case OfferApplicantsStatus.success:
            if (applicants.isEmpty) {
              return const Text('Aún no hay postulaciones para esta oferta.');
            }
            return Column(
              children: [
                for (final application in applicants)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ApplicantTile(
                      offerId: offer.id,
                      application: application,
                      companyUid: resolvedCompanyUid,
                    ),
                  ),
              ],
            );
        }
      },
    );
  }
}
