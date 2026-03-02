import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarLogic {
  const CalendarLogic._();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static List<CalendarEvent> eventsForRange({
    required Map<DateTime, List<CalendarEvent>> byDay,
    required DateTime start,
    required DateTime end,
  }) {
    final result = <CalendarEvent>[];
    var cursor = normalizeDate(start);
    final normalizedEnd = normalizeDate(end);

    while (!cursor.isAfter(normalizedEnd)) {
      result.addAll(byDay[cursor] ?? const <CalendarEvent>[]);
      cursor = cursor.add(const Duration(days: 1));
    }

    result.sort((left, right) => left.date.compareTo(right.date));
    return result;
  }

  static bool isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
