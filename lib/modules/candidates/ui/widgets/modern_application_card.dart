import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class ModernApplicationCard extends StatefulWidget {
  const ModernApplicationCard({
    super.key,
    required this.title,
    required this.company,
    this.avatarUrl,
    this.salary,
    this.location,
    this.modality,
    this.statusBadge,
    required this.onTap,
  });

  final String title;
  final String company;
  final String? avatarUrl;
  final String? salary;
  final String? location;
  final String? modality;
  final Widget? statusBadge;
  final VoidCallback? onTap;

  @override
  State<ModernApplicationCard> createState() => _ModernApplicationCardState();
}

class _ModernApplicationCardState extends State<ModernApplicationCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHoverChanged(true),
            onExit: (_) => _onHoverChanged(false),
            cursor: widget.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
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
                          blurRadius: _elevationAnimation.value,
                          offset: Offset(0, _elevationAnimation.value / 2),
                        ),
                      ],
                ),
                child: Stack(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Avatar + Company + Title
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
                                    child: (widget.avatarUrl != null &&
                                            widget.avatarUrl!.isNotEmpty)
                                        ? Image.network(
                                            widget.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
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
                              // Space for status badge
                              if (widget.statusBadge != null)
                                const SizedBox(width: 60),
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
                                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                ),
                              if (widget.location != null)
                                _InfoChip(
                                  icon: Icons.location_on_outlined,
                                  label: widget.location!,
                                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                                ),
                              if (widget.modality != null)
                                _InfoChip(
                                  icon: Icons.work_outline,
                                  label: widget.modality!,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Action indicator
                          if (widget.onTap != null)
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
                                Icon(
                                  Icons.arrow_forward,
                                  color: uiAccent,
                                  size: 16,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Status badge in top-right corner
                    if (widget.statusBadge != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: widget.statusBadge!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
