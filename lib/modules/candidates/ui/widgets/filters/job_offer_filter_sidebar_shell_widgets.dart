import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterSidebarHeader extends StatelessWidget {
  const JobOfferFilterSidebarHeader({super.key, required this.palette});

  final JobOfferFilterPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: palette.accent,
          size: JobOfferFilterSidebarTokens.headerIconSize,
        ),
        const SizedBox(width: uiSpacing8),
        Text(
          'Filtros',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
      ],
    );
  }
}

class JobOfferFilterSection extends StatelessWidget {
  const JobOfferFilterSection({
    super.key,
    required this.title,
    required this.icon,
    required this.palette,
    required this.child,
  });

  final String title;
  final IconData icon;
  final JobOfferFilterPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: JobOfferFilterSidebarTokens.sectionIconSize,
              color: palette.ink,
            ),
            const SizedBox(width: uiSpacing8 - 2),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: uiSpacing8),
        child,
      ],
    );
  }
}

class JobOfferClearFiltersButton extends StatelessWidget {
  const JobOfferClearFiltersButton({
    super.key,
    required this.palette,
    required this.onPressed,
  });

  final JobOfferFilterPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.clear_all, size: uiSpacing16 + 2),
        label: const Text('Limpiar filtros'),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(vertical: uiSpacing12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(uiSpacing8),
          ),
        ),
      ),
    );
  }
}
