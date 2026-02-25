import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CandidateOnboardingIntroStep extends StatelessWidget {
  const CandidateOnboardingIntroStep({
    super.key,
    required this.icon,
    required this.headline,
    required this.description,
    required this.highlights,
  });

  final IconData icon;
  final String headline;
  final String description;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(uiSpacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.45),
            colorScheme.secondaryContainer.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(uiSpacing12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(height: uiSpacing12),
          Text(
            headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: uiSpacing8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: uiSpacing16),
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: uiSpacing8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: uiSpacing8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
