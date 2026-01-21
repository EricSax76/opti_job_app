import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({super.key, required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final events = state.events[_normalize(state.selectedDay)] ?? const [];

    return Card(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No tienes recordatorios para este día.'),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(event.title),
      subtitle: event.description != null ? Text(event.description!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Eliminar',
        onPressed: () => context.read<CalendarCubit>().removeEvent(event.id),
      ),
    );
  }
}
