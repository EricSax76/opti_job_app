import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class InlineStateMessage extends StatelessWidget {
  const InlineStateMessage({
    super.key,
    this.icon,
    required this.message,
    this.action,
    this.color,
  });

  final IconData? icon;
  final String message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: uiSpacing12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? uiMuted, size: 20),
            const SizedBox(width: uiSpacing12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color ?? uiMuted,
                fontSize: 14,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: uiSpacing12),
            action!,
          ],
        ],
      ),
    );
  }
}
