import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/talent_pool/models/candidate_note.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';

part 'candidate_notes_state.dart';

class CandidateNotesCubit extends Cubit<CandidateNotesState> {
  CandidateNotesCubit({required TalentPoolRepository repository})
      : _repository = repository,
        super(const CandidateNotesState());

  final TalentPoolRepository _repository;
  StreamSubscription? _subscription;

  void subscribeToNotes(String candidateUid, String companyId) {
    emit(state.copyWith(status: CandidateNotesStatus.loading));
    _subscription?.cancel();
    _subscription = _repository.getCandidateNotes(candidateUid, companyId).listen(
      (notes) {
        emit(state.copyWith(
          status: CandidateNotesStatus.success,
          notes: notes,
        ));
      },
      onError: (_) {
        emit(state.copyWith(status: CandidateNotesStatus.failure));
      },
    );
  }

  Future<void> addNote(CandidateNote note) async {
    try {
      await _repository.addNote(note);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
