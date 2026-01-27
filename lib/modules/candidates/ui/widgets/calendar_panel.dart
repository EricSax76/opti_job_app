import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final events = state.events[_normalize(state.selectedDay)] ?? const [];

    return Card(
      elevation: 0,
      color: isDark ? uiDarkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiCardRadius),
        side: BorderSide(color: isDark ? uiDarkBorder : uiBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'No tienes recordatorios para este día.',
                  style: TextStyle(color: isDark ? uiDarkMuted : uiMuted),
                ),
              )
            else
              ...events.map((event) => _CalendarEventTile(event: event)),
          ],
        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        event.title,
        style: TextStyle(color: isDark ? uiDarkInk : uiInk),
      ),
      subtitle: event.description != null
          ? Text(
              event.description!,
              style: TextStyle(color: isDark ? uiDarkMuted : uiMuted),
            )
          : null,
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          color: isDark ? uiDarkMuted : uiMuted,
        ),
        tooltip: 'Eliminar',
        onPressed: () => context.read<CalendarCubit>().removeEvent(event.id),
      ),
    );
  }
}
