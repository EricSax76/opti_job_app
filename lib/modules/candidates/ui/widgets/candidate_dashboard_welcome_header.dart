import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CandidateDashboardWelcomeHeader extends StatelessWidget {
  const CandidateDashboardWelcomeHeader({
    super.key,
    required this.candidateName,
    required this.useCompactHeader,
    required this.shouldAutoHideHeader,
    required this.isVisible,
  });

  final String candidateName;
  final bool useCompactHeader;
  final bool shouldAutoHideHeader;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTitleColor = isDark
        ? uiDarkOnPrimaryContainer
        : uiLightOnPrimaryContainer;
    final headerSubtitleColor = headerTitleColor.withValues(alpha: 0.82);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
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
                  horizontal: useCompactHeader ? 14 : 24,
                  vertical: useCompactHeader ? 12 : 24,
                ),
                decoration: BoxDecoration(
                  color: useCompactHeader
                      ? (isDark
                          ? uiDarkHeaderGradientStart.withValues(alpha: 0.75)
                          : uiLightHeaderGradientStart.withValues(alpha: 0.85))
                      : null,
                  gradient: useCompactHeader
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
                    Text(
                      'Hola, $candidateName',
                      style: (useCompactHeader
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: headerTitleColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aquí tienes las mejores ofertas seleccionadas para ti.',
                      maxLines: useCompactHeader ? 2 : null,
                      overflow: useCompactHeader
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      style: (useCompactHeader
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)
                          ?.copyWith(color: headerSubtitleColor),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(key: ValueKey('dashboard_welcome_header_hidden')),
    );
  }
}
