import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_state.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';

class CurriculumCubit extends Cubit<CurriculumState> {
  CurriculumCubit({
    required CurriculumRepository repository,
    required CandidateAuthCubit candidateAuthCubit,
  }) : _repository = repository,
       _candidateAuthCubit = candidateAuthCubit,
       super(const CurriculumState()) {
    _authSubscription = _candidateAuthCubit.stream.listen(_onAuthStateChanged);
    _onAuthStateChanged(_candidateAuthCubit.state);
  }

  final CurriculumRepository _repository;
  final CandidateAuthCubit _candidateAuthCubit;
  StreamSubscription<CandidateAuthState>? _authSubscription;

  Future<void> _onAuthStateChanged(CandidateAuthState authState) async {
    final uid = authState.candidate?.uid;
    if (!authState.isAuthenticated || uid == null) {
      emit(const CurriculumState(status: CurriculumStatus.empty));
      return;
    }

    emit(state.copyWith(status: CurriculumStatus.loading, clearError: true));
    try {
      final curriculum = await _repository.fetchCurriculum(uid);
      emit(
        state.copyWith(status: CurriculumStatus.loaded, curriculum: curriculum),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CurriculumStatus.failure,
          errorMessage: 'No se pudo cargar tu curriculum.',
        ),
      );
    }
  }

  Future<void> refresh() {
    return _onAuthStateChanged(_candidateAuthCubit.state);
  }

  Future<void> save(Curriculum curriculum) async {
    final uid = _candidateAuthCubit.state.candidate?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          status: CurriculumStatus.failure,
          errorMessage: 'Usuario no autenticado.',
          clearCurriculum: false,
        ),
      );
      return;
    }

    emit(state.copyWith(status: CurriculumStatus.saving, clearError: true));
    try {
      final saved = await _repository.saveCurriculum(
        candidateUid: uid,
        curriculum: curriculum,
      );
      emit(state.copyWith(status: CurriculumStatus.loaded, curriculum: saved));
    } catch (_) {
      emit(
        state.copyWith(
          status: CurriculumStatus.failure,
          errorMessage: 'No se pudo guardar tu curriculum.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

