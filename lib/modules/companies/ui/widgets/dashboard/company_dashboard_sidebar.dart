import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/companies/models/company_dashboard_navigation.dart';

class CompanyDashboardSidebar extends StatefulWidget {
  const CompanyDashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  static const double collapsedWidth = 80;
  static const double expandedWidth = 260;

  final int selectedIndex;
  final List<CompanyDashboardNavItem> items;
  final ValueChanged<int> onSelected;

  @override
  State<CompanyDashboardSidebar> createState() =>
      _CompanyDashboardSidebarState();
}

class _CompanyDashboardSidebarState extends State<CompanyDashboardSidebar> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      width: _isCollapsed
          ? CompanyDashboardSidebar.collapsedWidth
          : CompanyDashboardSidebar.expandedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: uiShadowSm,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                for (final item in widget.items)
                  _CompanySidebarItem(
                    item: item,
                    isSelected: item.index == widget.selectedIndex,
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onSelected(item.index),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_isCollapsed)
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
                  )
                else
                  const _CompanyThemeToggle(),
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

class _CompanySidebarItem extends StatelessWidget {
  const _CompanySidebarItem({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  final CompanyDashboardNavItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final icon = Icon(
      item.icon,
      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
    );

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IconButton(
          onPressed: onTap,
          icon: icon,
          style: IconButton.styleFrom(
            backgroundColor: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : null,
          ),
          tooltip: item.label,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _CompanyThemeToggle extends StatelessWidget {
  const _CompanyThemeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;
        return InkWell(
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          borderRadius: BorderRadius.circular(uiFieldRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text('Tema oscuro')),
                Switch.adaptive(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
