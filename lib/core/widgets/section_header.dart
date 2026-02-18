import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell_breakpoints.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final isConstrainedWeb = kIsWeb && width < coreShellNavigationBreakpoint;
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor =
        Theme.of(context).textTheme.titleLarge?.color ?? colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;
    final resolvedTitleFontSize = isConstrainedWeb
        ? titleFontSize.clamp(18.0, 22.0)
        : titleFontSize;
    final showTagline = tagline != null && !isConstrainedWeb;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (showTagline) ...[
          Text(
            tagline!.toUpperCase(),
            style: TextStyle(
              color: subtitleColor,
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
                  fontSize: resolvedTitleFontSize,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: titleHeight,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: uiSpacing16),
              Flexible(fit: FlexFit.loose, child: action!),
            ],
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: isConstrainedWeb ? uiSpacing4 : uiSpacing8),
          Text(
            subtitle!,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            maxLines: isConstrainedWeb ? 1 : null,
            overflow: isConstrainedWeb
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(
              color: subtitleColor,
              fontSize: isConstrainedWeb ? 13 : 15,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
