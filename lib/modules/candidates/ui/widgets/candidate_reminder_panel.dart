import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/logic/calendar_logic.dart';
import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

enum CandidateReminderWindow { selectedDay, nextSevenDays }

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
        final selectedDay = CalendarLogic.normalizeDate(state.selectedDay);
        final today = CalendarLogic.normalizeDate(DateTime.now());
        final tomorrow = today.add(const Duration(days: 1));
        final isSevenDayWindow =
            window == CandidateReminderWindow.nextSevenDays;
        final windowStart = isSevenDayWindow ? today : selectedDay;
        final windowEnd = isSevenDayWindow
            ? today.add(const Duration(days: 6))
            : selectedDay;
        final events = isSevenDayWindow
            ? CalendarLogic.eventsForRange(
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
                color: colorScheme.surface.withValues(alpha: 0),
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
                                      CalendarLogic.isSameDay(
                                        selectedDay,
                                        today,
                                      ),
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
                                      CalendarLogic.isSameDay(
                                        selectedDay,
                                        tomorrow,
                                      ),
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
                                CandidateSidebarReminderRow(event: event),
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

class CandidateSidebarReminderRow extends StatelessWidget {
  const CandidateSidebarReminderRow({super.key, required this.event});

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
