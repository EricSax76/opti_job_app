import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/ui/widgets/application_status_badge.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_actions.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_details.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_header.dart';

class JobOfferDetailContent extends StatelessWidget {
  const JobOfferDetailContent({
    super.key,
    required this.state,
    required this.isAuthenticated,
    required this.companyAvatarUrl,
    required this.onApply,
    required this.onQualifiedSign,
    required this.onMatch,
    required this.onBack,
  });

  final JobOfferDetailState state;
  final bool isAuthenticated;
  final String? companyAvatarUrl;
  final VoidCallback onApply;
  final VoidCallback? onQualifiedSign;
  final VoidCallback? onMatch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (state.status == JobOfferDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOfferDetailStatus.failure && state.offer == null) {
      return StateMessage(
        title: 'Error',
        message: state.errorMessage ?? 'No se pudo cargar la oferta.',
      );
    }

    final offer = state.offer;
    if (offer == null) {
      return const StateMessage(
        title: 'Oferta no encontrada',
        message: 'Esta oferta ya no está disponible.',
      );
    }

    final isApplying = state.status == JobOfferDetailStatus.applying;
    final application = state.application;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobOfferHeader(
          offer: offer,
          companyAvatarUrl: companyAvatarUrl,
          statusChip: application == null
              ? null
              : ApplicationStatusBadge.fromString(application.status),
        ),
        const SizedBox(height: 14),
        Expanded(child: JobOfferDetails(offer: offer)),
        const SizedBox(height: 14),
        JobOfferActions(
          isAuthenticated: isAuthenticated,
          isApplying: isApplying,
          applicationStatus: application?.status,
          onApply: onApply,
          onQualifiedSign: onQualifiedSign,
          onMatch: onMatch,
          onBack: onBack,
        ),
      ],
    );
  }
}
