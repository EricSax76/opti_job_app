import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/data/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/features/profiles/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    required CandidateAuthCubit candidateAuthCubit,
  }) : _repository = repository,
       _candidateAuthCubit = candidateAuthCubit,
       super(const ProfileState()) {
    _authSubscription = _candidateAuthCubit.stream.listen(
      _onAuthStateChanged,
    ); // ignore: avoid_types_on_closure_parameters
    _onAuthStateChanged(_candidateAuthCubit.state);
  }

  final ProfileRepository _repository;
  final CandidateAuthCubit _candidateAuthCubit;
  StreamSubscription<CandidateAuthState>? _authSubscription;

  Future<void> _onAuthStateChanged(CandidateAuthState authState) async {
    if (!authState.isAuthenticated) {
      emit(const ProfileState(status: ProfileStatus.empty));
      return; // ignore: avoid_returning_null_for_void
    }

    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    try {
      if (authState.candidate != null) {
        final profile = await _repository.fetchCandidateProfile(
          authState.candidate!.id,
        );
        emit(state.copyWith(status: ProfileStatus.loaded, candidate: profile));
      } else {
        emit(state.copyWith(status: ProfileStatus.empty, clearCandidate: true));
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
