import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    required CandidateAuthCubit candidateAuthCubit,
  }) : _repository = repository,
       _candidateAuthCubit = candidateAuthCubit,
       super(const ProfileState());

  final ProfileRepository _repository;
  final CandidateAuthCubit _candidateAuthCubit;
  StreamSubscription<CandidateAuthState>? _authSubscription;

  Future<void> start() async {
    if (_authSubscription != null) return;
    _authSubscription = _candidateAuthCubit.stream.listen(_onAuthStateChanged);
    await _onAuthStateChanged(_candidateAuthCubit.state);
  }

  Future<void> _onAuthStateChanged(CandidateAuthState authState) async {
    if (!authState.isAuthenticated) {
      emit(const ProfileState(status: ProfileStatus.empty));
      return; // ignore: avoid_returning_null_for_void
    }

    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    try {
      if (authState.candidate != null) {
        final profile = await _repository.fetchCandidateProfile(
          authState.candidate!.uid,
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

  Future<void> refresh() async {
    await _onAuthStateChanged(_candidateAuthCubit.state);
  }

  void retry() => unawaited(refresh());

  Future<void> updateCandidateProfile({
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
    CandidateOnboardingProfile? onboardingProfile,
  }) async {
    final candidate = state.candidate ?? _candidateAuthCubit.state.candidate;
    if (candidate == null) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'No hay un candidato autenticado.',
        ),
      );
      return;
    }

    final hasBasicChanges =
        candidate.name.trim() != name ||
        candidate.lastName.trim() != lastName ||
        avatarBytes != null;
    final hasOnboardingChanges = onboardingProfile != null;

    if (!hasBasicChanges && !hasOnboardingChanges) {
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          candidate: candidate,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      var updatedCandidate = candidate;
      if (hasBasicChanges) {
        updatedCandidate = await _repository.updateCandidateProfile(
          uid: candidate.uid,
          name: name,
          lastName: lastName,
          avatarBytes: avatarBytes,
        );
      }
      if (onboardingProfile != null) {
        updatedCandidate = await _repository.saveCandidateOnboardingProfile(
          uid: candidate.uid,
          onboardingProfile: onboardingProfile,
        );
      }
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          candidate: updatedCandidate,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'No se pudo actualizar el perfil.',
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
