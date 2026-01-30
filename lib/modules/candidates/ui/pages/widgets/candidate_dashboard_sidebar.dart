import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';

class CandidateDashboardSidebar extends StatelessWidget {
  const CandidateDashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'OPTIJOB',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in candidateDashboardSidebarItems)
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    selected: item.index == selectedIndex,
                    selectedColor: colorScheme.onSecondaryContainer,
                    selectedTileColor:
                        colorScheme.secondaryContainer.withOpacity(0.6),
                    onTap: () => onSelected(item.index),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
