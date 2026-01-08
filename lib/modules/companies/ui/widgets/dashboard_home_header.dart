import 'package:flutter/material.dart';

class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOME',
          style: textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Dashboard',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Resumen rápido de tus ofertas y candidatos.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
