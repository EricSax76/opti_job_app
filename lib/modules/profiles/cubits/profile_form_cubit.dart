import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_state.dart';
import 'package:opti_job_app/modules/profiles/utils/candidate_name_utils.dart';

export 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';

class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit({required ProfileCubit profileCubit})
    : _profileCubit = profileCubit,
      nameController = TextEditingController(),
      lastNameController = TextEditingController(),
      emailController = TextEditingController(),
      targetRoleController = TextEditingController(),
      preferredLocationController = TextEditingController(),
      super(const ProfileFormState()) {
    nameController.addListener(_handleTextChanged);
    lastNameController.addListener(_handleTextChanged);
    targetRoleController.addListener(_handleTextChanged);
    preferredLocationController.addListener(_handleTextChanged);
  }

  static const CandidateOnboardingProfile _defaultOnboardingProfile =
      CandidateOnboardingProfile(
        targetRole: '',
        preferredLocation: '',
        preferredModality: '',
        preferredSeniority: '',
        workStyleSkipped: true,
      );

  Future<void> start() async {
    if (_profileSubscription != null) return;
    _profileSubscription = _profileCubit.stream.listen(_syncFromProfile);
    _syncFromProfile(_profileCubit.state);
  }

  final ProfileCubit _profileCubit;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController targetRoleController;
  final TextEditingController preferredLocationController;

  StreamSubscription<ProfileState>? _profileSubscription;
  String _initialName = '';
  String _initialLastName = '';
  ProfileStatus? _lastProfileStatus;
  bool _isHydratingControllers = false;

  Future<void> refresh() async {
    await _profileCubit.refresh();
  }

  void retry() => unawaited(refresh());

  void submit() {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (name.isEmpty || !state.canSubmit) return;
    final onboardingDraft = _syncDraftWithTextControllers(
      state.onboardingDraft,
    );
    final onboardingHasChanges = onboardingDraft != state.onboardingProfile;
    if (onboardingHasChanges && !_hasMinimumProfileData(onboardingDraft)) {
      emit(
        state.copyWith(
          onboardingDraft: onboardingDraft,
          notice: ProfileFormNotice.error,
          noticeMessage:
              'Completa rol objetivo, modalidad, ubicación y seniority para guardar preferencias.',
        ),
      );
      return;
    }

    _profileCubit.updateCandidateProfile(
      name: name,
      lastName: lastName,
      avatarBytes: state.avatarBytes,
      onboardingProfile: onboardingHasChanges
          ? _normalizeOnboardingDraft(onboardingDraft)
          : null,
    );
  }

  void updatePreferredModality(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(preferredModality: value.trim()),
    );
  }

  void updatePreferredSeniority(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(preferredSeniority: value.trim()),
    );
  }

  void updateWorkStyleSkipped(bool value) {
    _updateOnboardingDraft((current) {
      if (value) {
        return current.copyWith(
          workStyleSkipped: true,
          clearStartOfDayPreference: true,
          clearFeedbackPreference: true,
          clearStructurePreference: true,
          clearTaskPacePreference: true,
        );
      }
      return current.copyWith(workStyleSkipped: false);
    });
  }

  void updateStartOfDayPreference(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(
        startOfDayPreference: value.trim(),
        workStyleSkipped: false,
      ),
    );
  }

  void updateFeedbackPreference(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(
        feedbackPreference: value.trim(),
        workStyleSkipped: false,
      ),
    );
  }

  void updateStructurePreference(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(
        structurePreference: value.trim(),
        workStyleSkipped: false,
      ),
    );
  }

  void updateTaskPacePreference(String value) {
    _updateOnboardingDraft(
      (current) => current.copyWith(
        taskPacePreference: value.trim(),
        workStyleSkipped: false,
      ),
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
      final onboardingDraft = _syncDraftWithTextControllers(
        state.onboardingDraft,
      );
      final hasChanges = _computeHasChanges(
        firstName: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        avatarBytes: bytes,
        onboardingProfile: state.onboardingProfile,
        onboardingDraft: onboardingDraft,
      );
      emit(
        state.copyWith(
          avatarBytes: bytes,
          onboardingDraft: onboardingDraft,
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
    if (_isHydratingControllers) return;

    final trimmed = nameController.text.trim();
    final trimmedLastName = lastNameController.text.trim();
    final onboardingDraft = _syncDraftWithTextControllers(
      state.onboardingDraft,
    );
    final hasChanges = _computeHasChanges(
      firstName: trimmed,
      lastName: trimmedLastName,
      avatarBytes: state.avatarBytes,
      onboardingProfile: state.onboardingProfile,
      onboardingDraft: onboardingDraft,
    );
    final canSubmit = _canSubmit(hasChanges, state.isSaving);
    emit(
      state.copyWith(
        onboardingDraft: onboardingDraft,
        hasChanges: hasChanges,
        canSubmit: canSubmit,
      ),
    );
  }

  void _syncFromProfile(ProfileState profileState) {
    final candidate = profileState.candidate;
    final hasCandidate = candidate != null;
    final viewStatus = _resolveViewStatus(profileState, hasCandidate);
    final isSaving = profileState.status == ProfileStatus.saving;
    final justSaved =
        _lastProfileStatus == ProfileStatus.saving &&
        profileState.status == ProfileStatus.loaded;
    final shouldHydrateInputs =
        hasCandidate && (!state.hasChanges || justSaved);
    final sourceOnboardingProfile = _normalizeOnboardingDraft(
      candidate?.onboardingProfile ?? _defaultOnboardingProfile,
    );

    if (hasCandidate && shouldHydrateInputs) {
      _updateControllers(candidate, onboardingDraft: sourceOnboardingProfile);
    }

    final onboardingProfile = shouldHydrateInputs
        ? sourceOnboardingProfile
        : state.onboardingProfile;
    final onboardingDraft = shouldHydrateInputs
        ? sourceOnboardingProfile
        : _syncDraftWithTextControllers(state.onboardingDraft);
    final avatarBytes = justSaved ? null : state.avatarBytes;
    final hasChanges = justSaved
        ? false
        : _computeHasChanges(
            firstName: nameController.text.trim(),
            lastName: lastNameController.text.trim(),
            avatarBytes: avatarBytes,
            onboardingProfile: onboardingProfile,
            onboardingDraft: onboardingDraft,
          );

    var nextState = state.copyWith(
      viewStatus: viewStatus,
      candidateName: candidate != null
          ? formatCandidateName(candidate)
          : 'Candidato',
      isSaving: isSaving,
      avatarUrl: candidate?.avatarUrl,
      email: candidate?.email ?? '',
      onboardingProfile: onboardingProfile,
      onboardingDraft: onboardingDraft,
      avatarBytes: avatarBytes,
      hasChanges: hasChanges,
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

  void _updateControllers(
    Candidate candidate, {
    required CandidateOnboardingProfile onboardingDraft,
  }) {
    final splitName = resolveCandidateNames(candidate);
    _initialName = splitName.firstName;
    _initialLastName = splitName.lastName;

    _isHydratingControllers = true;
    try {
      nameController.text = splitName.firstName;
      lastNameController.text = splitName.lastName;
      emailController.text = candidate.email;
      targetRoleController.text = onboardingDraft.targetRole;
      preferredLocationController.text = onboardingDraft.preferredLocation;
    } finally {
      _isHydratingControllers = false;
    }
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
    required CandidateOnboardingProfile onboardingProfile,
    required CandidateOnboardingProfile onboardingDraft,
  }) {
    return firstName != _initialName ||
        lastName != _initialLastName ||
        avatarBytes != null ||
        onboardingDraft != onboardingProfile;
  }

  bool _canSubmit(bool hasChanges, bool isSaving) {
    return hasChanges && nameController.text.trim().isNotEmpty && !isSaving;
  }

  void _updateOnboardingDraft(
    CandidateOnboardingProfile Function(CandidateOnboardingProfile current)
    update,
  ) {
    final current = _syncDraftWithTextControllers(state.onboardingDraft);
    final nextDraft = _normalizeOnboardingDraft(update(current));
    final hasChanges = _computeHasChanges(
      firstName: nameController.text.trim(),
      lastName: lastNameController.text.trim(),
      avatarBytes: state.avatarBytes,
      onboardingProfile: state.onboardingProfile,
      onboardingDraft: nextDraft,
    );
    emit(
      state.copyWith(
        onboardingDraft: nextDraft,
        hasChanges: hasChanges,
        canSubmit: _canSubmit(hasChanges, state.isSaving),
      ),
    );
  }

  CandidateOnboardingProfile _syncDraftWithTextControllers(
    CandidateOnboardingProfile draft,
  ) {
    return draft.copyWith(
      targetRole: targetRoleController.text.trim(),
      preferredLocation: preferredLocationController.text.trim(),
    );
  }

  CandidateOnboardingProfile _normalizeOnboardingDraft(
    CandidateOnboardingProfile profile,
  ) {
    final targetRole = profile.targetRole.trim();
    final preferredLocation = profile.preferredLocation.trim();
    final preferredModality = profile.preferredModality.trim();
    final preferredSeniority = profile.preferredSeniority.trim();
    final workStyleSkipped = profile.workStyleSkipped;

    String? normalizeOptional(String? value) {
      if (workStyleSkipped) return null;
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    }

    return CandidateOnboardingProfile(
      targetRole: targetRole,
      preferredLocation: preferredLocation,
      preferredModality: preferredModality,
      preferredSeniority: preferredSeniority,
      workStyleSkipped: workStyleSkipped,
      startOfDayPreference: normalizeOptional(profile.startOfDayPreference),
      feedbackPreference: normalizeOptional(profile.feedbackPreference),
      structurePreference: normalizeOptional(profile.structurePreference),
      taskPacePreference: normalizeOptional(profile.taskPacePreference),
    );
  }

  bool _hasMinimumProfileData(CandidateOnboardingProfile profile) {
    return profile.targetRole.trim().isNotEmpty &&
        profile.preferredLocation.trim().isNotEmpty &&
        profile.preferredModality.trim().isNotEmpty &&
        profile.preferredSeniority.trim().isNotEmpty;
  }

  @override
  Future<void> close() {
    nameController.removeListener(_handleTextChanged);
    lastNameController.removeListener(_handleTextChanged);
    targetRoleController.removeListener(_handleTextChanged);
    preferredLocationController.removeListener(_handleTextChanged);
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    targetRoleController.dispose();
    preferredLocationController.dispose();
    _profileSubscription?.cancel();
    return super.close();
  }
}
