import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/offer_applicants_section.dart';
import 'package:opti_job_app/modules/job_offers/logic/offer_card_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/offer_card_controller.dart';

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
    final pillBackground = colorScheme.surface;

    final company = context.watch<CompanyAuthCubit>().state.company;
    final viewModel = OfferCardLogic.buildViewModel(
      offer: offer,
      companyUidFromAuth: company?.uid,
      avatarUrlFromAuth: company?.avatarUrl,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: uiCardRadius,
      backgroundColor: surface,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: uiSpacing16 + 2,
            vertical: uiSpacing8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            uiSpacing16 + 2,
            0,
            uiSpacing16 + 2,
            uiSpacing16 + 2,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: surfaceContainer,
            backgroundImage: (viewModel.avatarUrl != null)
                ? NetworkImage(viewModel.avatarUrl!)
                : null,
            child: (viewModel.avatarUrl == null)
                ? Icon(Icons.business_outlined, color: muted)
                : null,
          ),
          title: Text(
            offer.title,
            style: TextStyle(color: ink, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            viewModel.subtitle,
            style: TextStyle(color: muted, height: 1.4),
          ),
          onExpansionChanged: (expanded) =>
              OfferCardController.onExpansionChanged(
                context,
                expanded: expanded,
                offer: offer,
                companyUid: viewModel.companyUid,
              ),
          children: [
            Wrap(
              spacing: uiSpacing8,
              runSpacing: uiSpacing8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/job-offer/${offer.id}'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ver detalle'),
                ),
                InfoPill(
                  icon: Icons.tag_outlined,
                  label: 'Oferta #${offer.id}',
                  backgroundColor: pillBackground,
                  borderColor: colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: uiSpacing12),
            OfferApplicantsSection(
              offer: offer,
              companyUid: viewModel.companyUid,
            ),
          ],
        ),
      ),
    );
  }
}
