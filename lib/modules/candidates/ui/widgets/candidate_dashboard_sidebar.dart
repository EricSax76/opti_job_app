import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_sidebar_item.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_theme_toggle.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_reminder_panel.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';

class CandidateDashboardSidebar extends StatefulWidget {
  const CandidateDashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.alignToRight = false,
  });

  static const double collapsedWidth = 80;
  static const double expandedWidth = 260;

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool alignToRight;

  @override
  State<CandidateDashboardSidebar> createState() =>
      _CandidateDashboardSidebarState();
}

class _CandidateDashboardSidebarState extends State<CandidateDashboardSidebar> {
  bool _isCollapsed = false;
  bool _isCalendarExpanded = false;
  CandidateReminderWindow _calendarWindow = CandidateReminderWindow.selectedDay;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _isCalendarExpanded = false;
        _calendarWindow = CandidateReminderWindow.selectedDay;
      }
    });
  }

  void _toggleCalendarSection() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
    });
  }

  IconData _toggleIcon() {
    if (widget.alignToRight) {
      return _isCollapsed
          ? Icons.keyboard_double_arrow_left
          : Icons.keyboard_double_arrow_right;
    }
    return _isCollapsed
        ? Icons.keyboard_double_arrow_right
        : Icons.keyboard_double_arrow_left;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sidebar = Semantics(
      container: true,
      label: 'Menú lateral de navegación de candidato',
      expanded: !_isCollapsed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: _isCollapsed ? Curves.easeInCubic : Curves.easeOutSine,
        width: _isCollapsed
            ? CandidateDashboardSidebar.collapsedWidth
            : CandidateDashboardSidebar.expandedWidth,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            left: widget.alignToRight
                ? BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  )
                : BorderSide.none,
            right: widget.alignToRight
                ? BorderSide.none
                : BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
          ),
          boxShadow: uiShadowSm,
        ),
        clipBehavior: Clip.hardEdge,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useCompactVisuals =
                _isCollapsed || constraints.maxWidth < 180;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    children: [
                      for (final item in candidateDashboardSidebarItems)
                        if (item.label != 'Entrevistas' ||
                            FeatureFlags.interviews)
                          CandidateDashboardSidebarItem(
                            item: item,
                            isSelected: item.index == widget.selectedIndex,
                            isCollapsed: useCompactVisuals,
                            onTap: () => widget.onSelected(item.index),
                            colorScheme: colorScheme,
                          ),
                      if (!useCompactVisuals) ...[
                        const SizedBox(height: 12),
                        CandidateReminderPanel(
                          isExpanded: _isCalendarExpanded,
                          onToggle: _toggleCalendarSection,
                          window: _calendarWindow,
                          onWindowChanged: (window) {
                            setState(() {
                              _calendarWindow = window;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (!useCompactVisuals)
                        const CandidateDashboardThemeToggle()
                      else
                        Semantics(
                          button: true,
                          label: 'Cambiar tema',
                          child: IconButton(
                            onPressed: () =>
                                context.read<ThemeCubit>().toggleTheme(),
                            icon: BlocBuilder<ThemeCubit, ThemeState>(
                              builder: (context, state) {
                                final isDark =
                                    state.themeMode == ThemeMode.dark;
                                return Icon(
                                  isDark ? Icons.light_mode : Icons.dark_mode,
                                );
                              },
                            ),
                            tooltip: 'Cambiar tema',
                          ),
                        ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: _isCollapsed
                            ? 'Expandir menú lateral'
                            : 'Colapsar menú lateral',
                        child: IconButton(
                          onPressed: _toggleCollapse,
                          icon: Icon(
                            _toggleIcon(),
                            color: colorScheme.onSurfaceVariant,
                          ),
                          tooltip: _isCollapsed ? 'Expandir' : 'Colapsar',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (!_isCollapsed) return sidebar;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        children: [
          sidebar,
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Expandir menú lateral',
              hint: 'Pulsa Enter o Espacio para expandir',
              child: FocusableActionDetector(
                mouseCursor: SystemMouseCursors.click,
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
                },
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      _toggleCollapse();
                      return null;
                    },
                  ),
                },
                child: Material(
                  color: colorScheme.surface.withValues(alpha: 0),
                  child: InkWell(
                    onTap: _toggleCollapse,
                    splashColor: colorScheme.primary.withValues(alpha: 0.08),
                    hoverColor: colorScheme.primary.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
