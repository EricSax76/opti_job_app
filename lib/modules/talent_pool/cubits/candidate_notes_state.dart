part of 'candidate_notes_cubit.dart';

enum CandidateNotesStatus { initial, loading, success, failure }

class CandidateNotesState extends Equatable {
  const CandidateNotesState({
    this.status = CandidateNotesStatus.initial,
    this.notes = const [],
  });

  final CandidateNotesStatus status;
  final List<CandidateNote> notes;

  @override
  List<Object?> get props => [status, notes];

  CandidateNotesState copyWith({
    CandidateNotesStatus? status,
    List<CandidateNote>? notes,
  }) {
    return CandidateNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
