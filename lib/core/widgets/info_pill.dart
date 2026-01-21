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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: uiSpacing12,
        vertical: uiSpacing4 + 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? uiBackground,
        borderRadius: BorderRadius.circular(uiPillRadius),
        border: Border.all(color: borderColor ?? uiBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: iconColor ?? uiMuted,
            ),
            const SizedBox(width: uiSpacing8 - 2),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? uiInk,
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
