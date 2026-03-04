import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final events = state.events[_normalize(state.selectedDay)] ?? const [];

    return AppCard(
      borderRadius: uiCardRadius,
      borderColor: colorScheme.outlineVariant,
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recordatorios (${events.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final date = state.selectedDay;
                  context.read<CalendarCubit>().addEvent(
                    date: date,
                    title: 'Seguimiento de oferta',
                    description:
                        'Revisa el estado de tus postulaciones en ${date.day}/${date.month}',
                    ownerType: 'candidate',
                  );
                },
              ),
            ],
          ),
          if (state.status == CalendarStatus.loading)
            const LinearProgressIndicator(),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: uiSpacing8),
              child: Text(
                'No tienes recordatorios para este día.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...events.map((event) => _CalendarEventTile(event: event)),
        ],
      ),
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final date = event.date;
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    // Determine style based on metadata or title
    // ownerType 'company' or 'candidate' doesn't distinguish interview vs reminder well if used generically.
    // But title contains "Entrevista".
    final isInterview = event.title.contains('Entrevista');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeStr,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      title: Text(
        event.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: isInterview ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: event.description != null
          ? Text(
              event.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
        tooltip: 'Eliminar',
        onPressed: () => context.read<CalendarCubit>().removeEvent(event.id),
      ),
    );
  }
}
