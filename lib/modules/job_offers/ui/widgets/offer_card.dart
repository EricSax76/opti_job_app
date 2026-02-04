import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/offer_applicants_section.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? colorScheme.surface;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final border = colorScheme.outline;

    final resolvedCompanyUid = _companyUid(context);
    final avatarUrl = context
        .watch<CompanyAuthCubit>()
        .state
        .company
        ?.avatarUrl;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(uiCardRadius),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: surfaceContainer,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(Icons.business_outlined, color: muted)
                  : null,
            ),
            title: Text(
              offer.title,
              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${offer.location} • ${offer.jobType ?? 'Tipología no especificada'}',
              style: TextStyle(color: muted, height: 1.4),
            ),
            onExpansionChanged: (expanded) {
              if (!expanded) return;

              final applicantsCubit = context.read<OfferApplicantsCubit>();
              final currentStatus =
                  applicantsCubit.state.statuses[offer.id] ??
                  OfferApplicantsStatus.initial;
              if (currentStatus != OfferApplicantsStatus.initial &&
                  currentStatus != OfferApplicantsStatus.failure) {
                return;
              }

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
            },
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/job-offer/${offer.id}'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Ver detalle'),
                  ),
                  Chip(
                    label: Text('Oferta #${offer.id}'),
                    side: BorderSide(color: border),
                    backgroundColor: surface,
                    labelStyle: TextStyle(color: ink),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OfferApplicantsSection(
                offer: offer,
                companyUid: resolvedCompanyUid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _companyUid(BuildContext context) {
    return offer.companyUid ??
        context.read<CompanyAuthCubit>().state.company?.uid;
  }
}
