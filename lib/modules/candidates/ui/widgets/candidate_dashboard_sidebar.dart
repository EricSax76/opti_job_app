import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/models/calendar_event.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_interviews_badge.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';

enum CandidateReminderWindow { selectedDay, nextSevenDays }

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

    return AnimatedContainer(
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
          final useCompactVisuals = _isCollapsed || constraints.maxWidth < 180;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    for (final item in candidateDashboardSidebarItems)
                      if (item.label != 'Entrevistas' ||
                          FeatureFlags.interviews)
                        _SidebarItem(
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
                      const _ThemeToggle()
                    else
                      IconButton(
                        onPressed: () =>
                            context.read<ThemeCubit>().toggleTheme(),
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
                        _toggleIcon(),
                        color: colorScheme.onSurfaceVariant,
                      ),
                      tooltip: _isCollapsed ? 'Expandir' : 'Colapsar',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

class CandidateReminderPanel extends StatelessWidget {
  const CandidateReminderPanel({
    super.key,
    required this.isExpanded,
    this.onToggle,
    this.collapsible = true,
    required this.window,
    required this.onWindowChanged,
  });

  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool collapsible;
  final CandidateReminderWindow window;
  final ValueChanged<CandidateReminderWindow> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final selectedDay = _normalizeDate(state.selectedDay);
        final today = _normalizeDate(DateTime.now());
        final tomorrow = today.add(const Duration(days: 1));
        final isSevenDayWindow =
            window == CandidateReminderWindow.nextSevenDays;
        final windowStart = isSevenDayWindow ? today : selectedDay;
        final windowEnd = isSevenDayWindow
            ? today.add(const Duration(days: 6))
            : selectedDay;
        final events = isSevenDayWindow
            ? _eventsForRange(
                byDay: state.events,
                start: windowStart,
                end: windowEnd,
              )
            : state.events[selectedDay] ?? const <CalendarEvent>[];
        final visibleEvents = events
            .take(isSevenDayWindow ? 6 : 3)
            .toList(growable: false);
        final remainingEvents = events.length - visibleEvents.length;
        final hasEvents = visibleEvents.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(uiFieldRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(uiFieldRadius),
                  onTap: collapsible ? onToggle : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recordatorios',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${events.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        if (collapsible) ...[
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSevenDayWindow
                                  ? 'Próx. 7 días (${windowStart.day}/${windowStart.month} - ${windowEnd.day}/${windowEnd.month})'
                                  : 'Día ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Hoy'),
                                  selected:
                                      !isSevenDayWindow &&
                                      _isSameDay(selectedDay, today),
                                  onSelected: (_) {
                                    onWindowChanged(
                                      CandidateReminderWindow.selectedDay,
                                    );
                                    _selectQuickDay(
                                      context: context,
                                      state: state,
                                      day: today,
                                    );
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                                ChoiceChip(
                                  label: const Text('Mañana'),
                                  selected:
                                      !isSevenDayWindow &&
                                      _isSameDay(selectedDay, tomorrow),
                                  onSelected: (_) {
                                    onWindowChanged(
                                      CandidateReminderWindow.selectedDay,
                                    );
                                    _selectQuickDay(
                                      context: context,
                                      state: state,
                                      day: tomorrow,
                                    );
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                                ChoiceChip(
                                  label: const Text('Próx. 7 días'),
                                  selected: isSevenDayWindow,
                                  onSelected: (_) {
                                    onWindowChanged(
                                      CandidateReminderWindow.nextSevenDays,
                                    );
                                    _selectQuickDay(
                                      context: context,
                                      state: state,
                                      day: today,
                                    );
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  final date = state.selectedDay;
                                  context.read<CalendarCubit>().addEvent(
                                    date: date,
                                    title: 'Seguimiento de oferta',
                                    description:
                                        'Revisa tus postulaciones en ${date.day}/${date.month}',
                                    ownerType: 'candidate',
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_alarm_outlined,
                                  size: 16,
                                ),
                                label: const Text('Añadir'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                            if (state.status == CalendarStatus.loading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (!hasEvents)
                              Text(
                                isSevenDayWindow
                                    ? 'Sin recordatorios para los próximos 7 días.'
                                    : 'Sin recordatorios para este día.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (hasEvents)
                              for (final event in visibleEvents)
                                _SidebarReminderRow(event: event),
                            if (remainingEvents > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '+$remainingEvents más',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static List<CalendarEvent> _eventsForRange({
    required Map<DateTime, List<CalendarEvent>> byDay,
    required DateTime start,
    required DateTime end,
  }) {
    final result = <CalendarEvent>[];
    var cursor = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);

    while (!cursor.isAfter(normalizedEnd)) {
      result.addAll(byDay[cursor] ?? const <CalendarEvent>[]);
      cursor = cursor.add(const Duration(days: 1));
    }

    result.sort((left, right) => left.date.compareTo(right.date));
    return result;
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static void _selectQuickDay({
    required BuildContext context,
    required CalendarState state,
    required DateTime day,
  }) {
    final cubit = context.read<CalendarCubit>();
    cubit.selectDay(day);

    if (state.focusedDay.year != day.year ||
        state.focusedDay.month != day.month) {
      cubit.loadMonth(DateTime(day.year, day.month));
    }
  }
}

class _SidebarReminderRow extends StatelessWidget {
  const _SidebarReminderRow({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = event.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final hour =
        '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              hour,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (hasDescription)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () =>
                context.read<CalendarCubit>().removeEvent(event.id),
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurface),
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 140) {
              return IconButton(
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Cambiar tema',
              );
            }
            final showLabel = constraints.maxWidth >= 210;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tema oscuro',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
