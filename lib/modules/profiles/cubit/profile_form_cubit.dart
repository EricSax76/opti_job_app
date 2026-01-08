import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_state.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_form_state.dart';
import 'package:opti_job_app/modules/profiles/utils/candidate_name_utils.dart';

export 'package:opti_job_app/modules/profiles/cubit/profile_form_state.dart';

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
    emit(state.copyWith(hasChanges: hasChanges, canSubmit: canSubmit));
  }

  void _syncFromProfile(ProfileState profileState) {
    final candidate = profileState.candidate;
    final hasCandidate = candidate != null;
    final viewStatus = _resolveViewStatus(profileState, hasCandidate);
    final isSaving = profileState.status == ProfileStatus.saving;
    final justSaved =
        _lastProfileStatus == ProfileStatus.saving &&
        profileState.status == ProfileStatus.loaded;

    if (hasCandidate && (!state.hasChanges || justSaved)) {
      _updateControllers(candidate, justSaved: justSaved);
    }

    var nextState = state.copyWith(
      viewStatus: viewStatus,
      candidateName: candidate != null
          ? formatCandidateName(candidate)
          : 'Candidato',
      isSaving: isSaving,
      avatarUrl: candidate?.avatarUrl,
      email: candidate?.email ?? '',
      avatarBytes: justSaved ? null : state.avatarBytes,
      hasChanges: justSaved ? false : state.hasChanges,
      errorMessage: viewStatus == ProfileFormViewStatus.error
          ? profileState.errorMessage
          : null,
      clearError: viewStatus != ProfileFormViewStatus.error,
    );

    nextState = _applyNotice(profileState, nextState);
    final canSubmit = _canSubmit(nextState.hasChanges, nextState.isSaving);

    _lastProfileStatus = profileState.status;
    emit(nextState.copyWith(canSubmit: canSubmit));
  }

  void _updateControllers(Candidate candidate, {required bool justSaved}) {
    final splitName = resolveCandidateNames(candidate);
    if (justSaved) {
      _initialName = splitName.firstName;
      _initialLastName = splitName.lastName;
    }
    nameController.text = splitName.firstName;
    lastNameController.text = splitName.lastName;
    emailController.text = candidate.email;
  }

  ProfileFormState _applyNotice(
    ProfileState profileState,
    ProfileFormState currentState,
  ) {
    if (_lastProfileStatus == ProfileStatus.saving &&
        profileState.status == ProfileStatus.loaded) {
      return currentState.copyWith(
        notice: ProfileFormNotice.success,
        noticeMessage: 'Perfil actualizado.',
      );
    }

    if (profileState.status == ProfileStatus.failure &&
        profileState.errorMessage != null) {
      return currentState.copyWith(
        notice: ProfileFormNotice.error,
        noticeMessage: profileState.errorMessage!,
      );
    }

    return currentState;
  }

  ProfileFormViewStatus _resolveViewStatus(
    ProfileState profileState,
    bool hasCandidate,
  ) {
    switch (profileState.status) {
      case ProfileStatus.initial:
      case ProfileStatus.loading:
        if (profileState.candidate == null) {
          return ProfileFormViewStatus.loading;
        }
        break;
      case ProfileStatus.failure:
        if (!hasCandidate) {
          return ProfileFormViewStatus.error;
        }
        break;
      case ProfileStatus.empty:
        return ProfileFormViewStatus.empty;
      case ProfileStatus.saving:
      case ProfileStatus.loaded:
        break;
    }
    return ProfileFormViewStatus.ready;
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
