import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/data/models/candidate.dart';
import 'package:opti_job_app/data/models/company.dart';
import 'package:opti_job_app/data/repositories/profile_repository.dart';
import 'package:opti_job_app/features/auth/cubit/auth_cubit.dart';

enum ProfileStatus { initial, loading, loaded, failure, empty }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.candidate,
    this.company,
    this.errorMessage,
  });

  final ProfileStatus status;
  final Candidate? candidate;
  final Company? company;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    Candidate? candidate,
    Company? company,
    String? errorMessage,
    bool clearCandidate = false,
    bool clearCompany = false,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      candidate: clearCandidate ? null : candidate ?? this.candidate,
      company: clearCompany ? null : company ?? this.company,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    required AuthCubit authCubit,
  }) : _repository = repository,
       _authCubit = authCubit,
       super(const ProfileState()) {
    _authSubscription = _authCubit.stream.listen(_onAuthStateChanged);
    _onAuthStateChanged(_authCubit.state);
  }

  final ProfileRepository _repository;
  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> _onAuthStateChanged(AuthState authState) async {
    if (!authState.isAuthenticated) {
      emit(const ProfileState(status: ProfileStatus.empty));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    try {
      if (authState.isCandidate && authState.candidate != null) {
        final profile = await _repository.fetchCandidateProfile(
          authState.candidate!.id,
        );
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            candidate: profile,
            clearCompany: true,
          ),
        );
      } else if (authState.isCompany && authState.company != null) {
        final profile = await _repository.fetchCompanyProfile(
          authState.company!.id,
        );
        emit(
          state.copyWith(
            status: ProfileStatus.loaded,
            company: profile,
            clearCandidate: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ProfileStatus.empty,
            clearCandidate: true,
            clearCompany: true,
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
