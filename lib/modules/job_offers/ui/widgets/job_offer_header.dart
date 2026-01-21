import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class JobOfferHeader extends StatelessWidget {
  const JobOfferHeader({
    super.key,
    required this.offer,
    this.companyAvatarUrl,
    this.statusChip,
  });

  final JobOffer offer;
  final String? companyAvatarUrl;
  final Widget? statusChip;

  @override
  Widget build(BuildContext context) {
    final title = offer.title.trim().isEmpty ? 'Oferta' : offer.title.trim();
    final company = offer.companyName?.trim().isNotEmpty == true
        ? offer.companyName!.trim()
        : 'Empresa no especificada';
    final salary = offer.formattedSalary;
    final modality = offer.jobType?.trim().isNotEmpty == true
        ? offer.jobType!.trim()
        : 'Modalidad no especificada';
    final location = offer.location.trim().isEmpty
        ? 'Ubicación no especificada'
        : offer.location;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.work_outline, color: uiInk),
              ),
              const SizedBox(width: uiSpacing12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: uiInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              if (statusChip != null) ...[
                const SizedBox(width: uiSpacing12),
                statusChip!,
              ],
            ],
          ),
          const SizedBox(height: uiSpacing12 - 2),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: uiBackground,
                backgroundImage:
                    (companyAvatarUrl != null &&
                        companyAvatarUrl!.trim().isNotEmpty)
                    ? NetworkImage(companyAvatarUrl!.trim())
                    : null,
                child:
                    (companyAvatarUrl == null ||
                        companyAvatarUrl!.trim().isEmpty)
                    ? const Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: uiMuted,
                      )
                    : null,
              ),
              const SizedBox(width: uiSpacing8),
              Expanded(
                child: Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: uiMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          Wrap(
            spacing: uiSpacing8,
            runSpacing: uiSpacing8,
            children: [
              if (salary != null)
                InfoPill(icon: Icons.payments_outlined, label: salary),
              InfoPill(icon: Icons.home_work_outlined, label: modality),
              InfoPill(icon: Icons.place_outlined, label: location),
            ],
          ),
        ],
      ),
    );
  }
}

