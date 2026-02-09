import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class ModernJobOfferCard extends StatefulWidget {
  const ModernJobOfferCard({
    super.key,
    required this.title,
    required this.company,
    this.avatarUrl,
    this.salary,
    this.location,
    this.modality,
    this.tags,
    required this.onTap,
  });

  final String title;
  final String company;
  final String? avatarUrl;
  final String? salary;
  final String? location;
  final String? modality;
  final List<String>? tags;
  final VoidCallback onTap;

  @override
  State<ModernJobOfferCard> createState() => _ModernJobOfferCardState();
}

class _ModernJobOfferCardState extends State<ModernJobOfferCard> {
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

    final ink = isDark ? uiDarkInk : uiInk;
    final muted = isDark ? uiDarkMuted : uiMuted;
    final borderColor = isDark ? uiDarkBorder : uiBorder;
    final surfaceColor = isDark ? uiDarkBackground : uiBackground;

    final gradientColors = isDark
        ? [uiDarkCardGradientStart, uiDarkCardGradientEnd]
        : [Colors.white, const Color(0xFFF8F9FA)];
    final avatarImageCacheSize = (44 * MediaQuery.of(context).devicePixelRatio)
        .round();
    final shadowBlurRadius = _isHovered ? 8.0 : 2.0;
    final shadowOffsetY = _isHovered ? 4.0 : 1.0;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: _hoverAnimationDuration,
          curve: Curves.easeOut,
          scale: _isHovered ? 1.02 : 1.0,
          child: AnimatedContainer(
            duration: _hoverAnimationDuration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? uiAccent.withValues(alpha: isDark ? 0.5 : 0.3)
                    : borderColor,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: shadowBlurRadius,
                        offset: Offset(0, shadowOffsetY),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar + Company
                  Row(
                    children: [
                      Hero(
                        tag: 'avatar_${widget.title}_${widget.company}',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDark ? uiDarkSurfaceLight : surfaceColor,
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child:
                                (widget.avatarUrl != null &&
                                    widget.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.avatarUrl!,
                                    fit: BoxFit.cover,
                                    cacheWidth: avatarImageCacheSize,
                                    cacheHeight: avatarImageCacheSize,
                                    filterQuality: FilterQuality.low,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.business_outlined,
                                          color: muted,
                                          size: 24,
                                        ),
                                  )
                                : Icon(
                                    Icons.business_outlined,
                                    color: muted,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.company,
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: ink,
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
                  const SizedBox(height: 10),

                  // Info Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (widget.salary != null)
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label: widget.salary!,
                          color: isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF059669),
                        ),
                      if (widget.location != null)
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: widget.location!,
                          color: isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                        ),
                      if (widget.modality != null)
                        _InfoChip(
                          icon: Icons.work_outline,
                          label: widget.modality!,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB),
                        ),
                    ],
                  ),

                  // Tags
                  if (widget.tags != null && widget.tags!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.tags!.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: uiAccent.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isDark
                                  ? uiAccent.withValues(alpha: 0.9)
                                  : uiAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          color: uiAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: uiAccent, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
