import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_logic.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/cards/candidate_offer_card_widgets.dart';

class CandidateOfferCardBase extends StatefulWidget {
  const CandidateOfferCardBase({
    super.key,
    required this.title,
    required this.company,
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
          scale: effectiveHovered ? 1.02 : 1.0,
          child: AppCard(
            onTap: widget.onTap,
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            borderColor: decoration.borderColor,
            borderWidth: decoration.borderWidth,
            backgroundColor: palette.backgroundColor,
            gradient: palette.gradient,
            boxShadow: decoration.boxShadow,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          child: _TitleBlock(
                            company: widget.company,
                            title: widget.title,
                            palette: palette,
                          ),
                        ),
                        if (widget.topRightBadge != null)
                          const SizedBox(width: 60),
                      ],
                    ),
                    if (metrics.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: metrics
                            .map(
                              (metric) =>
                                  CandidateOfferMetricPill(metric: metric),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => CandidateOfferTagPill(
                                label: tag,
                                palette: palette,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    if (hasTapAction) ...[
                      const SizedBox(height: 8),
                      CandidateOfferActionIndicator(
                        actionLabel: widget.actionLabel,
                      ),
                    ],
                  ],
                ),
                if (widget.topRightBadge != null)
                  Positioned(top: 0, right: 0, child: widget.topRightBadge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.company,
    required this.title,
    required this.palette,
  });

  final String company;
  final String title;
  final CandidateOfferCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          company,
          style: TextStyle(
            color: palette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          title,
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
    );
  }
}
