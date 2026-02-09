import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_models.dart';

class CandidateOfferCardLogic {
  const CandidateOfferCardLogic._();

  static CandidateOfferCardDecoration resolveDecoration({
    required CandidateOfferCardPalette palette,
    required bool isDark,
    required bool isHovered,
  }) {
    final blurRadius = isHovered ? 8.0 : 2.0;
    final offsetY = isHovered ? 4.0 : 1.0;
    return CandidateOfferCardDecoration(
      borderColor: isHovered
          ? uiAccent.withValues(alpha: isDark ? 0.5 : 0.3)
          : palette.borderColor,
      borderWidth: isHovered ? 1.5 : 1,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: blurRadius,
                offset: Offset(0, offsetY),
              ),
            ],
    );
  }

  static List<CandidateOfferMetricData> buildMetrics({
    required bool isDark,
    String? salary,
    String? location,
    String? modality,
  }) {
    final metrics = <CandidateOfferMetricData>[];
    if (_hasText(salary)) {
      metrics.add(
        CandidateOfferMetricData(
          icon: Icons.payments_outlined,
          label: salary!.trim(),
          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
        ),
      );
    }
    if (_hasText(location)) {
      metrics.add(
        CandidateOfferMetricData(
          icon: Icons.location_on_outlined,
          label: location!.trim(),
          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
        ),
      );
    }
    if (_hasText(modality)) {
      metrics.add(
        CandidateOfferMetricData(
          icon: Icons.work_outline,
          label: modality!.trim(),
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        ),
      );
    }
    return metrics;
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
