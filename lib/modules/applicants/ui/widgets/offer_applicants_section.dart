import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_tile.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_interaction_cubit.dart';
import 'package:opti_job_app/modules/applicants/logic/offer_applicants_section_logic.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';

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
      buildWhen: (previous, current) =>
          OfferApplicantsSectionLogic.shouldRebuildOfferApplicants(
            previous: previous,
            current: current,
            offerId: offer.id,
          ),
      builder: (context, state) {
        final viewModel = OfferApplicantsSectionLogic.buildViewModel(
          state: state,
          offerId: offer.id,
        );

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

        switch (viewModel.status) {
          case OfferApplicantsStatus.initial:
            return message(l10n.applicantsExpandToLoad);
          case OfferApplicantsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          case OfferApplicantsStatus.failure:
            return message(viewModel.errorMessage ?? l10n.applicantsLoadError);
          case OfferApplicantsStatus.success:
            if (viewModel.applicants.isEmpty) {
              return message(l10n.applicantsEmpty);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.applicants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final application = viewModel.applicants[index];
                final isAnonymousScreening = shouldAnonymizeApplication(
                  application,
                );
                return ApplicantTile(
                  application: application,
                  onTap:
                      application.candidateUid.trim().isEmpty ||
                          isAnonymousScreening
                      ? null
                      : () => context.pushNamed(
                          'company-applicant-cv',
                          pathParameters: {
                            'offerId': offer.id,
                            'uid': application.candidateUid,
                          },
                        ),
                  onStatusChanged: application.id == null
                      ? null
                      : (newStatus) {
                          context
                              .read<OfferApplicantsCubit>()
                              .updateApplicationStatus(
                                offerId: offer.id,
                                applicationId: application.id!,
                                newStatus: newStatus,
                                companyUid: resolvedCompanyUid,
                              );
                        },
                  onStartInterview: application.id == null
                      ? null
                      : () => OfferApplicantsSectionLogic.requestInterviewStart(
                          context: context,
                          interactionCubit: context
                              .read<ApplicantInteractionCubit>(),
                          applicationId: application.id!,
                        ),
                );
              },
            );
        }
      },
    );
  }
}
