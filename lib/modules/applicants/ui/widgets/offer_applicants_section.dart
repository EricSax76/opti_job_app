import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_tile.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final muted = colorScheme.onSurfaceVariant;
    final border = colorScheme.outline;

    final resolvedCompanyUid = companyUid;
    if (resolvedCompanyUid == null) {
      return Text(
        l10n.applicantsMissingCompanyId,
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
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(uiTileRadius),
              border: Border.all(color: border),
            ),
            child: Text(text, style: TextStyle(color: muted, height: 1.4)),
          );
        }

        switch (status) {
          case OfferApplicantsStatus.initial:
            return message(l10n.applicantsExpandToLoad);
          case OfferApplicantsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          case OfferApplicantsStatus.failure:
            return message(error ?? l10n.applicantsLoadError);
          case OfferApplicantsStatus.success:
            if (applicants.isEmpty) {
              return message(l10n.applicantsEmpty);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applicants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final application = applicants[index];
                return ApplicantTile(
                  offerId: offer.id,
                  application: application,
                  companyUid: resolvedCompanyUid,
                );
              },
            );
        }
      },
    );
  }
}
