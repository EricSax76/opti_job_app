import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.tagline,
    required this.title,
    required this.subtitle,
    this.titleFontSize = 26,
    this.titleHeight = 1.2,
  });

  final String tagline;
  final String title;
  final String subtitle;
  final double titleFontSize;
  final double titleHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tagline,
          style: const TextStyle(
            color: uiMuted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: uiInk,
            height: titleHeight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: uiMuted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}
