import 'package:flutter/material.dart';
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
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

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

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.work_outline, color: ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              if (statusChip != null) ...[
                const SizedBox(width: 12),
                statusChip!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFFF8FAFC),
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
                        color: muted,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (salary != null)
                _InfoPill(icon: Icons.payments_outlined, label: salary),
              _InfoPill(icon: Icons.home_work_outlined, label: modality),
              _InfoPill(icon: Icons.place_outlined, label: location),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
