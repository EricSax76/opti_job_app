class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    this.ownerType,
  });

  final String id;
  final String title;
  final DateTime date;
  final String? description;
  final String? ownerType;

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    String? ownerType,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      ownerType: ownerType ?? this.ownerType,
    );
  }
}
