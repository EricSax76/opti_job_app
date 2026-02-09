import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterSidebarHeader extends StatelessWidget {
  const JobOfferFilterSidebarHeader({super.key, required this.palette});

  final JobOfferFilterPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: palette.accent,
          size: JobOfferFilterSidebarTokens.headerIconSize,
        ),
        const SizedBox(width: 8),
        Text(
          'Filtros',
          style: TextStyle(
            fontSize: JobOfferFilterSidebarTokens.headerTitleFontSize,
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
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: JobOfferFilterSidebarTokens.sectionTitleFontSize,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        icon: const Icon(Icons.clear_all, size: 18),
        label: const Text('Limpiar filtros'),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
