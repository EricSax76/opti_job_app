import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_offer_card_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_offer_card_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_widgets.dart';

class CandidateOfferCardBase extends StatefulWidget {
  const CandidateOfferCardBase({
    super.key,
    required this.title,
    required this.company,
    this.description,
    this.avatarUrl,
    this.salary,
    this.location,
    this.modality,
    this.tags,
    this.heroTag,
    required this.heroTagPrefix,
    this.topRightBadge,
    this.onTap,
    this.actionLabel = 'Ver detalles',
  });

  final String title;
  final String company;
  final String? description;
  final String? avatarUrl;
  final String? salary;
  final String? location;
  final String? modality;
  final List<String>? tags;
  final Object? heroTag;
  final String heroTagPrefix;
  final Widget? topRightBadge;
  final VoidCallback? onTap;
  final String actionLabel;

  @override
  State<CandidateOfferCardBase> createState() => _CandidateOfferCardBaseState();
}

class _CandidateOfferCardBaseState extends State<CandidateOfferCardBase> {
  static const Duration _hoverAnimationDuration = Duration(milliseconds: 200);
  bool _isHovered = false;

  void _onHoverChanged(bool isHovered) {
    if (_isHovered == isHovered) return;
    setState(() => _isHovered = isHovered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasTapAction = widget.onTap != null;
    final effectiveHovered = hasTapAction && _isHovered;

    final palette = CandidateOfferCardPalette.fromTheme(theme);
    final decoration = CandidateOfferCardLogic.resolveDecoration(
      palette: palette,
      isDark: isDark,
      isHovered: effectiveHovered,
    );
    final metrics = CandidateOfferCardLogic.buildMetrics(
      isDark: isDark,
      salary: widget.salary,
      location: widget.location,
      modality: widget.modality,
    );
    final tags =
        widget.tags
            ?.where((tag) => tag.trim().isNotEmpty)
            .take(2)
            .toList(growable: false) ??
        const <String>[];
    final avatarImageCacheSize = (44 * MediaQuery.of(context).devicePixelRatio)
        .round();

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(hasTapAction),
      onExit: (_) => _onHoverChanged(false),
      cursor: hasTapAction
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Material(
        color: Colors.transparent,
        child: AnimatedScale(
          duration: _hoverAnimationDuration,
          curve: Curves.easeOut,
          scale: effectiveHovered ? 1.01 : 1.0,
          child: AppCard(
            onTap: widget.onTap,
            padding: EdgeInsets.zero, // Custom padding inside
            borderRadius: 16,
            borderColor: decoration.borderColor,
            borderWidth: decoration.borderWidth,
            backgroundColor: palette.backgroundColor,
            gradient: palette.gradient,
            boxShadow: decoration.boxShadow,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Info, Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CandidateOfferAvatar(
                            avatarUrl: widget.avatarUrl,
                            heroTag: widget.heroTag,
                            heroTagPrefix: widget.heroTagPrefix,
                            palette: palette,
                            avatarImageCacheSize: avatarImageCacheSize,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.company,
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.topRightBadge != null) ...[
                                      const SizedBox(width: 8),
                                      // Scale down badge slightly if needed or wrap
                                      widget.topRightBadge!,
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description (Optional)
                      if (widget.description != null &&
                          widget.description!.isNotEmpty) ...[
                        Text(
                          _normalizeDescription(widget.description),
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Footer: Tags & Metrics
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...tags.map(
                            (tag) => CandidateOfferTagPill(
                              label: tag,
                              palette: palette,
                            ),
                          ),
                          if (tags.isNotEmpty && metrics.isNotEmpty)
                            VerticalDivider(
                              width: 1,
                              color: palette.borderColor,
                            ),
                          ...metrics.map(
                            (metric) =>
                                CandidateOfferMetricPill(metric: metric),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Keep the action indicator subtle at bottom right or remove if redundant
                // For now, let's just use the card tap. If an explicit action is needed:
                if (hasTapAction)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: palette.muted.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _normalizeDescription(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
