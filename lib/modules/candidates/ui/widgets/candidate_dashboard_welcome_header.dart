import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CandidateDashboardWelcomeHeader extends StatelessWidget {
  const CandidateDashboardWelcomeHeader({
    super.key,
    required this.candidateName,
    required this.titleText,
    required this.subtitleText,
    this.assistiveHint,
    required this.useCompactHeader,
    required this.shouldAutoHideHeader,
    required this.isVisible,
    this.simplified = false,
  });

  final String candidateName;
  final String titleText;
  final String subtitleText;
  final String? assistiveHint;
  final bool useCompactHeader;
  final bool shouldAutoHideHeader;
  final bool isVisible;
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTitleColor = isDark
        ? uiDarkOnPrimaryContainer
        : uiLightOnPrimaryContainer;
    final headerSubtitleColor = headerTitleColor.withValues(alpha: 0.82);

    return AnimatedSwitcher(
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: (!shouldAutoHideHeader || isVisible)
          ? Padding(
              key: const ValueKey('dashboard_welcome_header_visible'),
              padding: EdgeInsets.only(bottom: useCompactHeader ? 12 : 24),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: simplified
                      ? 12
                      : (useCompactHeader ? 14 : 24),
                  vertical: simplified
                      ? 10
                      : (useCompactHeader ? 12 : 24),
                ),
                decoration: BoxDecoration(
                  color: simplified
                      ? theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: isDark ? 0.42 : 0.55,
                        )
                      : useCompactHeader
                      ? (isDark
                            ? uiDarkHeaderGradientStart.withValues(alpha: 0.75)
                            : uiLightHeaderGradientStart.withValues(
                                alpha: 0.85,
                              ))
                      : null,
                  gradient: simplified || useCompactHeader
                      ? null
                      : (isDark
                            ? const LinearGradient(
                                colors: [
                                  uiDarkHeaderGradientStart,
                                  uiDarkHeaderGradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [
                                  uiLightHeaderGradientStart,
                                  uiLightHeaderGradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )),
                  borderRadius: BorderRadius.circular(
                    useCompactHeader ? 14 : uiCardRadius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Cabecera personalizada',
                      value: '$candidateName. $titleText',
                      child: Text(
                        titleText,
                        style:
                            (useCompactHeader
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: headerTitleColor,
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!simplified)
                      Text(
                        subtitleText,
                        maxLines: useCompactHeader ? 2 : null,
                        overflow: useCompactHeader
                            ? TextOverflow.ellipsis
                            : TextOverflow.visible,
                        style:
                            (useCompactHeader
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(color: headerSubtitleColor),
                      ),
                    if (!simplified &&
                        assistiveHint != null &&
                        assistiveHint!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            size: 16,
                            color: headerSubtitleColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              assistiveHint!,
                              maxLines: useCompactHeader ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: headerSubtitleColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            )
          : const SizedBox(key: ValueKey('dashboard_welcome_header_hidden')),
    );
  }
}
