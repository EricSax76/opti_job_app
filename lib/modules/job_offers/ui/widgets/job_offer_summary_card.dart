import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';

class JobOfferSummaryCard extends StatelessWidget {
  const JobOfferSummaryCard({
    super.key,
    required this.title,
    required this.company,
    this.avatarUrl,
    this.salary,
    this.modality,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String company;
  final String? avatarUrl;
  final String? salary;
  final String? modality;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(uiSpacing16),
      borderRadius: uiTileRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.work_outline, color: uiInk),
          ),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: uiInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: uiSpacing12),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: uiSpacing4 + 2),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: uiBackground,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl!.isNotEmpty)
                              ? NetworkImage(avatarUrl!)
                              : null,
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? const Icon(
                              Icons.business_outlined,
                              size: 12,
                              color: uiMuted,
                            )
                          : null,
                    ),
                    const SizedBox(width: uiSpacing8 - 2),
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
                if ((salary != null && salary!.trim().isNotEmpty) ||
                    (modality != null && modality!.trim().isNotEmpty)) ...[
                  const SizedBox(height: uiSpacing12 - 2),
                  Wrap(
                    spacing: uiSpacing8,
                    runSpacing: uiSpacing8,
                    children: [
                      if (salary != null && salary!.trim().isNotEmpty)
                        InfoPill(icon: Icons.payments_outlined, label: salary!),
                      if (modality != null && modality!.trim().isNotEmpty)
                        InfoPill(
                            icon: Icons.home_work_outlined, label: modality!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: uiSpacing8 + 2),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: uiMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

