import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/calendar/models/calendar_event.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';

enum CalendarStatus { initial, loading, ready, failure }

class CalendarState {
  CalendarState({
    this.status = CalendarStatus.initial,
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<CalendarEvent>>? events,
    this.errorMessage,
  }) : focusedDay = focusedDay ?? DateTime.now(),
       selectedDay = selectedDay ?? DateTime.now(),
       events = events ?? const {};

  final CalendarStatus status;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<CalendarEvent>> events;
  final String? errorMessage;

  CalendarState copyWith({
    CalendarStatus? status,
    DateTime? focusedDay,
    DateTime? selectedDay,
    Map<DateTime, List<CalendarEvent>>? events,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CalendarState(
      status: status ?? this.status,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      events: events ?? this.events,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit(this._repository) : super(CalendarState());

  final CalendarRepository _repository;

  Future<void> loadMonth(DateTime month) async {
    emit(state.copyWith(status: CalendarStatus.loading, clearError: true));
    try {
      final events = await _repository.fetchMonth(month);
      emit(
        state.copyWith(
          status: CalendarStatus.ready,
          events: events,
          focusedDay: DateTime(month.year, month.month),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CalendarStatus.failure,
          errorMessage: 'No se pudieron cargar los eventos.',
        ),
      );
    }
  }

  Future<void> addEvent({
    required DateTime date,
    required String title,
    String? description,
    String? ownerType,
  }) async {
    try {
      await _repository.addEvent(
        date: date,
        title: title,
        description: description,
        ownerType: ownerType,
      );
      await loadMonth(state.focusedDay);
      selectDay(date);
    } catch (error) {
      emit(
        state.copyWith(
          status: CalendarStatus.failure,
          errorMessage: 'No se pudo crear el recordatorio.',
        ),
      );
    }
  }

  Future<void> removeEvent(String eventId) async {
    try {
      await _repository.removeEvent(eventId);
      await loadMonth(state.focusedDay);
    } catch (error) {
      emit(
        state.copyWith(
          status: CalendarStatus.failure,
          errorMessage: 'No se pudo eliminar el recordatorio.',
        ),
      );
    }
  }

  void selectDay(DateTime day) {
    emit(state.copyWith(selectedDay: DateTime(day.year, day.month, day.day)));
  }
}
