import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
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
    this.avatarBytes,
    this.avatarUrl,
    this.email = '',
    this.errorMessage,
    this.notice,
    this.noticeMessage,
  });

  final ProfileFormViewStatus viewStatus;
  final bool hasChanges;
  final bool canSubmit;
  final bool isSaving;
  final String candidateName;
  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final String email;
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
    avatarBytes,
    avatarUrl,
    email,
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
    Uint8List? avatarBytes,
    String? avatarUrl,
    String? email,
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
      avatarBytes: avatarBytes ?? this.avatarBytes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
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
      lastNameController = TextEditingController(),
      emailController = TextEditingController(),
      super(const ProfileFormState()) {
    nameController.addListener(_handleTextChanged);
    lastNameController.addListener(_handleTextChanged);
    _profileSubscription = _profileCubit.stream.listen(_syncFromProfile);
    _syncFromProfile(_profileCubit.state);
  }

  final ProfileCubit _profileCubit;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;

  StreamSubscription<ProfileState>? _profileSubscription;
  String _initialName = '';
  String _initialLastName = '';
  ProfileStatus? _lastProfileStatus;

  void refresh() {
    _profileCubit.refreshProfile();
  }

  void submit() {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (name.isEmpty || !state.canSubmit) return;
    _profileCubit.updateCandidateProfile(
      name: name,
      lastName: lastName,
      avatarBytes: state.avatarBytes,
    );
  }

  void clearNotice() {
    if (state.notice != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final hasChanges = _computeHasChanges(
        firstName: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        avatarBytes: bytes,
      );
      emit(
        state.copyWith(
          avatarBytes: bytes,
          hasChanges: hasChanges,
          canSubmit: _canSubmit(hasChanges, state.isSaving),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          notice: ProfileFormNotice.error,
          noticeMessage: 'No se pudo seleccionar la imagen.',
        ),
      );
    }
  }

  void _handleTextChanged() {
    final trimmed = nameController.text.trim();
    final trimmedLastName = lastNameController.text.trim();
    final hasChanges = _computeHasChanges(
      firstName: trimmed,
      lastName: trimmedLastName,
      avatarBytes: state.avatarBytes,
    );
    final canSubmit = _canSubmit(hasChanges, state.isSaving);
    if (hasChanges != state.hasChanges || canSubmit != state.canSubmit) {
      emit(state.copyWith(hasChanges: hasChanges, canSubmit: canSubmit));
    }
  }

  void _syncFromProfile(ProfileState profileState) {
    final candidate = profileState.candidate;
    final hasCandidate = candidate != null;
    final viewStatus = _resolveViewStatus(profileState, hasCandidate);
    var candidateName = 'Candidato';
    if (candidate != null && candidate.name.isNotEmpty) {
      candidateName = _formatCandidateName(candidate);
    }
    final isSaving = profileState.status == ProfileStatus.saving;
    final justSaved =
        _lastProfileStatus == ProfileStatus.saving &&
        profileState.status == ProfileStatus.loaded;

    if (hasCandidate && !state.hasChanges) {
      final splitName = _resolveCandidateNames(candidate);
      _initialName = splitName.firstName;
      _initialLastName = splitName.lastName;
      nameController.text = splitName.firstName;
      lastNameController.text = splitName.lastName;
      emailController.text = candidate.email;
    }

    var nextState = state.copyWith(
      viewStatus: viewStatus,
      candidateName: candidateName,
      isSaving: isSaving,
      avatarUrl: candidate?.avatarUrl,
      email: candidate?.email ?? '',
      avatarBytes: justSaved ? null : state.avatarBytes,
      hasChanges: justSaved ? false : state.hasChanges,
      errorMessage: viewStatus == ProfileFormViewStatus.error
          ? profileState.errorMessage
          : null,
      clearError: viewStatus != ProfileFormViewStatus.error,
      canSubmit:
          (justSaved ? false : state.hasChanges) &&
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
      final splitName = _resolveCandidateNames(profileState.candidate);
      _initialName = splitName.firstName;
      _initialLastName = splitName.lastName;
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

  bool _computeHasChanges({
    required String firstName,
    required String lastName,
    required Uint8List? avatarBytes,
  }) {
    return firstName != _initialName ||
        lastName != _initialLastName ||
        avatarBytes != null;
  }

  bool _canSubmit(bool hasChanges, bool isSaving) {
    return hasChanges && nameController.text.trim().isNotEmpty && !isSaving;
  }

  _SplitName _resolveCandidateNames(Candidate? candidate) {
    if (candidate == null) {
      return const _SplitName('', '');
    }
    if (candidate.lastName.isNotEmpty) {
      return _SplitName(candidate.name, candidate.lastName);
    }
    return _splitCandidateName(candidate.name);
  }

  String _formatCandidateName(Candidate candidate) {
    final name = candidate.name.trim();
    final lastName = candidate.lastName.trim();
    if (lastName.isEmpty) {
      return name.isNotEmpty ? name : 'Candidato';
    }
    return '$name $lastName'.trim();
  }

  _SplitName _splitCandidateName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return const _SplitName('', '');
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _SplitName(parts.first, '');
    }
    return _SplitName(parts.first, parts.sublist(1).join(' '));
  }

  @override
  Future<void> close() {
    nameController.removeListener(_handleTextChanged);
    lastNameController.removeListener(_handleTextChanged);
    nameController.dispose();
    lastNameController.dispose();
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

class _SplitName {
  const _SplitName(this.firstName, this.lastName);

  final String firstName;
  final String lastName;
}
