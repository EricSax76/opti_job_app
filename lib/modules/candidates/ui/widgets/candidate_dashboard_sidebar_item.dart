import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_interviews_badge.dart';

class CandidateDashboardSidebarItem extends StatelessWidget {
  const CandidateDashboardSidebarItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    required this.colorScheme,
  });

  final CandidateDashboardNavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = item.index == 2
        ? CandidateInterviewsBadge(
            child: Icon(
              item.icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          )
        : Icon(
            item.icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IconButton(
          onPressed: onTap,
          icon: icon,
          style: IconButton.styleFrom(
            backgroundColor: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null,
          ),
          tooltip: item.label,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: icon,
        title: Text(
          item.label,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(uiFieldRadius),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
