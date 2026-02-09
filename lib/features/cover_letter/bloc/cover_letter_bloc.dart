import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

part 'cover_letter_event.dart';
part 'cover_letter_state.dart';

typedef CurriculumProvider = Curriculum? Function();
typedef CandidateUidProvider = String? Function();

class CoverLetterBloc extends Bloc<CoverLetterEvent, CoverLetterState> {
  CoverLetterBloc({
    required AiRepository aiRepository,
    required CoverLetterRepository coverLetterRepository,
    required CurriculumProvider curriculumProvider,
    required CandidateUidProvider candidateUidProvider,
  }) : _aiRepository = aiRepository,
       _coverLetterRepository = coverLetterRepository,
       _curriculumProvider = curriculumProvider,
       _candidateUidProvider = candidateUidProvider,
       super(const CoverLetterState()) {
    on<LoadCoverLetterRequested>(_onLoadCoverLetterRequested);
    on<ImproveCoverLetterRequested>(_onImproveCoverLetterRequested);
    on<SaveCoverLetterRequested>(_onSaveCoverLetterRequested);
  }

  final AiRepository _aiRepository;
  final CoverLetterRepository _coverLetterRepository;
  final CurriculumProvider _curriculumProvider;
  final CandidateUidProvider _candidateUidProvider;

  Future<void> _onLoadCoverLetterRequested(
    LoadCoverLetterRequested event,
    Emitter<CoverLetterState> emit,
  ) async {
    final uid = _candidateUidProvider();
    if (uid == null) return;

    emit(state.copyWith(status: CoverLetterStatus.loading, error: () => null));
    try {
      final text = await _coverLetterRepository.fetchCoverLetterText(uid);

      emit(
        state.copyWith(
          status: CoverLetterStatus.initial,
          savedCoverLetterText: (text == null || text.isEmpty) ? null : text,
          improvedCoverLetter: null,
          error: () => null,
        ),
      );
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message ?? 'No se pudo cargar tu carta.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onImproveCoverLetterRequested(
    ImproveCoverLetterRequested event,
    Emitter<CoverLetterState> emit,
  ) async {
    try {
      final curriculum = _curriculumProvider();
      if (curriculum == null) {
        emit(
          state.copyWith(
            status: CoverLetterStatus.failure,
            error: () =>
                'Completa tu CV primero para que la IA pueda generar una carta.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CoverLetterStatus.improving,
          improvedCoverLetter: null,
          error: () => null,
        ),
      );

      final improvedText = await _aiRepository.improveCoverLetter(
        curriculum: curriculum,
        coverLetterText: event.originalText,
        locale: event.locale,
      );
      emit(
        state.copyWith(
          status: CoverLetterStatus.success,
          improvedCoverLetter: improvedText,
          error: () => null,
        ),
      );
    } on AiConfigurationException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message,
        ),
      );
    } on AiRequestException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveCoverLetterRequested(
    SaveCoverLetterRequested event,
    Emitter<CoverLetterState> emit,
  ) async {
    final coverLetterText = event.coverLetterText.trim();
    if (coverLetterText.isEmpty) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => 'Escribe tu carta antes de guardar.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CoverLetterStatus.saving,
        improvedCoverLetter: null,
        error: () => null,
      ),
    );
    try {
      final uid = _candidateUidProvider();
      if (uid == null) {
        emit(
          state.copyWith(
            status: CoverLetterStatus.failure,
            error: () => 'Debes iniciar sesión para guardar.',
          ),
        );
        return;
      }

      await _coverLetterRepository.saveCoverLetterText(
        candidateUid: uid,
        text: coverLetterText,
      );

      emit(
        state.copyWith(
          status: CoverLetterStatus.success,
          savedCoverLetterText: coverLetterText,
          improvedCoverLetter: null,
          error: () => null,
        ),
      );
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message ?? 'No se pudo guardar tu carta.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }
}
