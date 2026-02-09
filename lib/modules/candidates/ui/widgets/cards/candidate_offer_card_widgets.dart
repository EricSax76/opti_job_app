import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_models.dart';

class CandidateOfferAvatar extends StatelessWidget {
  const CandidateOfferAvatar({
    super.key,
    required this.avatarUrl,
    required this.heroTag,
    required this.heroTagPrefix,
    required this.palette,
    required this.avatarImageCacheSize,
  });

  final String? avatarUrl;
  final Object? heroTag;
  final String heroTagPrefix;
  final CandidateOfferCardPalette palette;
  final int avatarImageCacheSize;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: palette.surfaceColor,
        border: Border.all(color: palette.borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _buildAvatarImage(),
      ),
    );

    if (heroTag == null) return avatar;
    return Hero(tag: '${heroTagPrefix}_$heroTag', child: avatar);
  }

  Widget _buildAvatarImage() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        cacheWidth: avatarImageCacheSize,
        cacheHeight: avatarImageCacheSize,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.business_outlined, color: palette.muted, size: 24),
      );
    }
    return Icon(Icons.business_outlined, color: palette.muted, size: 24);
  }
}

class CandidateOfferMetricPill extends StatelessWidget {
  const CandidateOfferMetricPill({super.key, required this.metric});

  final CandidateOfferMetricData metric;

  @override
  Widget build(BuildContext context) {
    return InfoPill(
      icon: metric.icon,
      label: metric.label,
      backgroundColor: metric.color.withValues(alpha: 0.1),
      borderColor: metric.color.withValues(alpha: 0.25),
      textColor: metric.color,
      iconColor: metric.color,
    );
  }
}

class CandidateOfferTagPill extends StatelessWidget {
  const CandidateOfferTagPill({
    super.key,
    required this.label,
    required this.palette,
  });

  final String label;
  final CandidateOfferCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return InfoPill(
      label: label,
      backgroundColor: palette.tagBackgroundColor,
      borderColor: palette.tagBorderColor,
      textColor: palette.tagTextColor,
      iconColor: palette.tagTextColor,
    );
  }
}

class CandidateOfferActionIndicator extends StatelessWidget {
  const CandidateOfferActionIndicator({super.key, required this.actionLabel});

  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          actionLabel,
          style: const TextStyle(
            color: uiAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_forward, color: uiAccent, size: 16),
      ],
    );
  }
}
