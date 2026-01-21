import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.tagline,
    required this.title,
    this.subtitle,
    this.action,
    this.titleFontSize = 26,
    this.titleHeight = 1.2,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String? tagline;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double titleFontSize;
  final double titleHeight;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (tagline != null) ...[
          Text(
            tagline!.toUpperCase(),
            style: const TextStyle(
              color: uiMuted,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: uiSpacing12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  height: titleHeight,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: uiSpacing16),
              action!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            subtitle!,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: const TextStyle(color: uiMuted, fontSize: 15, height: 1.4),
          ),
        ],
      ],
    );
  }
}

