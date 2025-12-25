import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:opti_job_app/features/calendar/models/calendar_event.dart';

class CalendarRepository {
  CalendarRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  Future<List<CalendarEvent>> fetchEventsFor(DateTime day) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final start = _normalize(day);
    final end = start.add(const Duration(days: 1));
    final baseQuery = _collection
        .where('owner_uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    try {
      final snapshot = await baseQuery.get();
      return snapshot.docs.map(_mapEvent).toList();
    } on FirebaseException catch (error) {
      final needsFallback =
          error.code == 'failed-precondition' &&
          (error.message?.toLowerCase().contains('index') ?? false);
      if (!needsFallback) rethrow;

      final snapshot = await _collection.where('owner_uid', isEqualTo: uid).get();
      final events = snapshot.docs.map(_mapEvent).where((event) {
        final eventDate = event.date;
        return !eventDate.isBefore(start) && eventDate.isBefore(end);
      }).toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    }
  }

  Future<Map<DateTime, List<CalendarEvent>>> fetchMonth(DateTime month) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final baseQuery = _collection
        .where('owner_uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date');

    late final List<CalendarEvent> events;
    try {
      final snapshot = await baseQuery.get();
      events = snapshot.docs.map(_mapEvent).toList();
    } on FirebaseException catch (error) {
      final needsFallback =
          error.code == 'failed-precondition' &&
          (error.message?.toLowerCase().contains('index') ?? false);
      if (!needsFallback) rethrow;

      final snapshot = await _collection.where('owner_uid', isEqualTo: uid).get();
      events = snapshot.docs.map(_mapEvent).where((event) {
        final eventDate = event.date;
        return !eventDate.isBefore(start) && eventDate.isBefore(end);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }

    final byDay = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final key = _normalize(event.date);
      byDay.putIfAbsent(key, () => <CalendarEvent>[]).add(event);
    }
    return byDay;
  }

  Future<CalendarEvent> addEvent({
    required DateTime date,
    required String title,
    String? description,
    String? ownerType,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Debe iniciar sesión para crear recordatorios.');
    }

    final normalizedDate = _normalize(date);
    final event = CalendarEvent(
      id: _uuid.v4(),
      title: title,
      date: normalizedDate,
      description: description,
      ownerType: ownerType,
    );
    await _collection.doc(event.id).set({
      'title': event.title,
      'description': event.description,
      'owner_type': event.ownerType,
      'owner_uid': uid,
      'date': Timestamp.fromDate(event.date),
      'created_at': FieldValue.serverTimestamp(),
    });
    return event;
  }

  Future<void> removeEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Debe iniciar sesión para eliminar recordatorios.');
    }
    await _collection.doc(eventId).delete();
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('calendarEvents');

  CalendarEvent _mapEvent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawDate = data['date'];
    final DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return CalendarEvent(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Recordatorio',
      date: date,
      description: data['description'] as String?,
      ownerType: data['owner_type'] as String?,
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
