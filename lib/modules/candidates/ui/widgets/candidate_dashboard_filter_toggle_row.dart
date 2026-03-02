import 'package:flutter/material.dart';

class CandidateDashboardFilterToggleRow extends StatelessWidget {
  const CandidateDashboardFilterToggleRow({
    super.key,
    required this.canPinFilters,
    required this.showFilters,
    required this.isMobileFiltersOpen,
    required this.onToggle,
  });

  final bool canPinFilters;
  final bool showFilters;
  final bool isMobileFiltersOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(
            canPinFilters
                ? (showFilters ? Icons.filter_list_off : Icons.filter_list)
                : (isMobileFiltersOpen
                    ? Icons.filter_list_off
                    : Icons.filter_list),
          ),
          label: Text(
            canPinFilters
                ? (showFilters ? 'Ocultar filtros' : 'Filtros')
                : (isMobileFiltersOpen ? 'Cerrar filtros' : 'Filtros'),
          ),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.secondary,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
