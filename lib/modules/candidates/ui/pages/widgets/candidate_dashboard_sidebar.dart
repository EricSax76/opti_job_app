import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_interviews_badge.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';

class CandidateDashboardSidebar extends StatefulWidget {
  const CandidateDashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<CandidateDashboardSidebar> createState() =>
      _CandidateDashboardSidebarState();
}

class _CandidateDashboardSidebarState extends State<CandidateDashboardSidebar> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: uiDurationNormal,
      width: _isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: uiShadowSm,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                for (final item in candidateDashboardSidebarItems)
                  if (item.label != 'Entrevistas' || FeatureFlags.interviews)
                    _SidebarItem(
                      item: item,
                      isSelected: item.index == widget.selectedIndex,
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onSelected(item.index),
                      colorScheme: colorScheme,
                    ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (!_isCollapsed)
                  _ThemeToggle(isCollapsed: false)
                else
                  IconButton(
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                    icon: BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        final isDark = state.themeMode == ThemeMode.dark;
                        return Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                        );
                      },
                    ),
                    tooltip: 'Cambiar tema',
                  ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: _toggleCollapse,
                  icon: Icon(
                    _isCollapsed
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: _isCollapsed ? 'Expandir' : 'Colapsar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
          style: TextStyle(
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

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          title: const Text('Tema oscuro', style: TextStyle(fontSize: 14)),
          trailing: Switch.adaptive(
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
          ),
        );
      },
    );
  }
}
