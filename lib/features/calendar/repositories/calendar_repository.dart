import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarRepository {
  CalendarRepository({Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      _events = {} {
    final today = _normalize(DateTime.now());
    _events[today] = [
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Bienvenida',
        date: today,
        description: 'Explora las oportunidades del día',
        ownerType: 'system',
      ),
    ];
  }

  final Uuid _uuid;
  final Map<DateTime, List<CalendarEvent>> _events;

  Future<List<CalendarEvent>> fetchEventsFor(DateTime day) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final key = _normalize(day);
    return List<CalendarEvent>.unmodifiable(_events[key] ?? const []);
  }

  Future<Map<DateTime, List<CalendarEvent>>> fetchMonth(DateTime month) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1);
    final entries = _events.entries.where(
      (entry) =>
          entry.key.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          entry.key.isBefore(lastDay.add(const Duration(days: 1))),
    );
    return Map<DateTime, List<CalendarEvent>>.fromEntries(entries);
  }

  Future<CalendarEvent> addEvent({
    required DateTime date,
    required String title,
    String? description,
    String? ownerType,
  }) async {
    final normalized = _normalize(date);
    final event = CalendarEvent(
      id: _uuid.v4(),
      title: title,
      date: normalized,
      description: description,
      ownerType: ownerType,
    );
    final events = _events.putIfAbsent(normalized, () => <CalendarEvent>[]);
    events.add(event);
    return event;
  }

  Future<void> removeEvent(String eventId) async {
    _events.updateAll((key, events) {
      events.removeWhere((event) => event.id == eventId);
      return events;
    });
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
