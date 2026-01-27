import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    this.icon,
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
  });

  final IconData? icon;
  final String label;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? uiDarkSurfaceLight.withValues(alpha: 0.5) : uiBackground;
    final defaultBorder = isDark ? uiDarkBorder : uiBorder;
    final defaultText = isDark ? uiDarkInk : uiInk;
    final defaultIcon = isDark ? uiDarkMuted : uiMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: uiSpacing12,
        vertical: uiSpacing4 + 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(uiPillRadius),
        border: Border.all(color: borderColor ?? defaultBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: iconColor ?? defaultIcon,
            ),
            const SizedBox(width: uiSpacing8 - 2),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? defaultText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
