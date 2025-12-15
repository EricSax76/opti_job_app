import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/data/models/candidate.dart';
import 'package:opti_job_app/data/models/company.dart';
import 'package:opti_job_app/data/repositories/profile_repository.dart';
import 'package:opti_job_app/auth/cubit/candidate_auth_cubit.dart';
import 'package:opti_job_app/auth/cubit/candidate_auth_state.dart';

enum ProfileStatus { initial, loading, loaded, failure, empty }

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    required CandidateAuthCubit candidateAuthCubit,
  }) : _repository = repository,
       _candidateAuthCubit = candidateAuthCubit,
       super(const ProfileState()) {
    _authSubscription = _candidateAuthCubit.stream.listen(_onAuthStateChanged);
    _onAuthStateChanged(_candidateAuthCubit.state);
  }

  final ProfileRepository _repository;
  final CandidateAuthCubit _candidateAuthCubit;
  StreamSubscription<CandidateAuthState>? _authSubscription;

  Future<void> _onAuthStateChanged(CandidateAuthState authState) async {
    if (!authState.isAuthenticated) {
      emit(const ProfileState(status: ProfileStatus.empty));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    try {
      if (authState.candidate != null) {
        final profile = await _repository.fetchCandidateProfile(
          authState.candidate!.id,
        );
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            candidate: profile,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ProfileStatus.empty,
            clearCandidate: true,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'No se pudo cargar el perfil.',
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
