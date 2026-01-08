import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/aplicants/applicant_tile.dart';
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
    const background = Color(0xFFF8FAFC);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    final resolvedCompanyUid = companyUid;
    if (resolvedCompanyUid == null) {
      return const Text(
        'No se pudieron cargar los aplicantes porque falta el identificador de empresa.',
        style: TextStyle(color: muted, height: 1.4),
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

        Widget message(String text) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Text(
              text,
              style: const TextStyle(color: muted, height: 1.4),
            ),
          );
        }

        switch (status) {
          case OfferApplicantsStatus.initial:
            return message(
              'Expande la tarjeta para cargar los aplicantes de esta oferta.',
            );
          case OfferApplicantsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          case OfferApplicantsStatus.failure:
            return message(error ?? 'No se pudieron cargar los aplicantes.');
          case OfferApplicantsStatus.success:
            if (applicants.isEmpty) {
              return message('Aún no hay postulaciones para esta oferta.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final application in applicants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
