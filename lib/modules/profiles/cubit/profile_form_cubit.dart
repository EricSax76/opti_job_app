import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_state.dart';

enum ProfileFormViewStatus { loading, empty, error, ready }

enum ProfileFormNotice { success, error }

class ProfileFormState extends Equatable {
  const ProfileFormState({
    this.viewStatus = ProfileFormViewStatus.loading,
    this.hasChanges = false,
    this.canSubmit = false,
    this.isSaving = false,
    this.candidateName = 'Candidato',
    this.errorMessage,
    this.notice,
    this.noticeMessage,
  });

  final ProfileFormViewStatus viewStatus;
  final bool hasChanges;
  final bool canSubmit;
  final bool isSaving;
  final String candidateName;
  final String? errorMessage;
  final ProfileFormNotice? notice;
  final String? noticeMessage;

  @override
  List<Object?> get props => [
        viewStatus,
        hasChanges,
        canSubmit,
        isSaving,
        candidateName,
        errorMessage,
        notice,
        noticeMessage,
      ];

  ProfileFormState copyWith({
    ProfileFormViewStatus? viewStatus,
    bool? hasChanges,
    bool? canSubmit,
    bool? isSaving,
    String? candidateName,
    String? errorMessage,
    ProfileFormNotice? notice,
    String? noticeMessage,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return ProfileFormState(
      viewStatus: viewStatus ?? this.viewStatus,
      hasChanges: hasChanges ?? this.hasChanges,
      canSubmit: canSubmit ?? this.canSubmit,
      isSaving: isSaving ?? this.isSaving,
      candidateName: candidateName ?? this.candidateName,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }
}

class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit({required ProfileCubit profileCubit})
      : _profileCubit = profileCubit,
        nameController = TextEditingController(),
        emailController = TextEditingController(),
        super(const ProfileFormState()) {
    nameController.addListener(_handleNameChanged);
    _profileSubscription = _profileCubit.stream.listen(_syncFromProfile);
    _syncFromProfile(_profileCubit.state);
  }

  final ProfileCubit _profileCubit;
  final TextEditingController nameController;
  final TextEditingController emailController;

  StreamSubscription<ProfileState>? _profileSubscription;
  String _initialName = '';
  ProfileStatus? _lastProfileStatus;

  void refresh() {
    _profileCubit.refreshProfile();
  }

  void submit() {
    final name = nameController.text.trim();
    if (name.isEmpty || !state.canSubmit) return;
    _profileCubit.updateCandidateProfile(name: name);
  }

  void clearNotice() {
    if (state.notice != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }

  void _handleNameChanged() {
    final trimmed = nameController.text.trim();
    final hasChanges = trimmed != _initialName;
    final canSubmit = hasChanges && trimmed.isNotEmpty && !state.isSaving;
    if (hasChanges != state.hasChanges || canSubmit != state.canSubmit) {
      emit(state.copyWith(hasChanges: hasChanges, canSubmit: canSubmit));
    }
  }

  void _syncFromProfile(ProfileState profileState) {
    final candidate = profileState.candidate;
    final hasCandidate = candidate != null;
    final viewStatus = _resolveViewStatus(profileState, hasCandidate);
    final candidateName = candidate?.name.isNotEmpty == true
        ? candidate!.name
        : 'Candidato';
    final isSaving = profileState.status == ProfileStatus.saving;

    if (hasCandidate && !state.hasChanges) {
      _initialName = candidate!.name;
      nameController.text = candidate.name;
      emailController.text = candidate.email;
    }

    var nextState = state.copyWith(
      viewStatus: viewStatus,
      candidateName: candidateName,
      isSaving: isSaving,
      errorMessage: viewStatus == ProfileFormViewStatus.error
          ? profileState.errorMessage
          : null,
      clearError: viewStatus != ProfileFormViewStatus.error,
      canSubmit: state.hasChanges &&
          nameController.text.trim().isNotEmpty &&
          !isSaving,
    );

    final noticeUpdate = _resolveNotice(profileState);
    if (noticeUpdate != null) {
      nextState = nextState.copyWith(
        notice: noticeUpdate.notice,
        noticeMessage: noticeUpdate.message,
      );
    }

    _lastProfileStatus = profileState.status;
    emit(nextState);
  }

  ProfileFormViewStatus _resolveViewStatus(
    ProfileState profileState,
    bool hasCandidate,
  ) {
    if (profileState.status == ProfileStatus.empty) {
      return ProfileFormViewStatus.empty;
    }
    if (profileState.status == ProfileStatus.failure && !hasCandidate) {
      return ProfileFormViewStatus.error;
    }
    if (profileState.status == ProfileStatus.loading &&
        profileState.candidate == null) {
      return ProfileFormViewStatus.loading;
    }
    return ProfileFormViewStatus.ready;
  }

  _NoticeUpdate? _resolveNotice(ProfileState profileState) {
    if (_lastProfileStatus == ProfileStatus.saving &&
        profileState.status == ProfileStatus.loaded) {
      _initialName = profileState.candidate?.name ?? _initialName;
      return _NoticeUpdate(
        notice: ProfileFormNotice.success,
        message: 'Perfil actualizado.',
      );
    }

    if (profileState.status == ProfileStatus.failure &&
        profileState.errorMessage != null) {
      return _NoticeUpdate(
        notice: ProfileFormNotice.error,
        message: profileState.errorMessage!,
      );
    }

    return null;
  }

  @override
  Future<void> close() {
    nameController.removeListener(_handleNameChanged);
    nameController.dispose();
    emailController.dispose();
    _profileSubscription?.cancel();
    return super.close();
  }
}

class _NoticeUpdate {
  _NoticeUpdate({required this.notice, required this.message});

  final ProfileFormNotice notice;
  final String message;
}
