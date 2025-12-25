import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_state.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

enum CurriculumFormViewStatus { loading, empty, error, ready }

enum CurriculumFormNotice { success, error }

class CurriculumFormState extends Equatable {
  const CurriculumFormState({
    this.viewStatus = CurriculumFormViewStatus.loading,
    this.hasChanges = false,
    this.canSubmit = false,
    this.isSaving = false,
    this.skills = const [],
    this.experiences = const [],
    this.education = const [],
    this.errorMessage,
    this.notice,
    this.noticeMessage,
  });

  final CurriculumFormViewStatus viewStatus;
  final bool hasChanges;
  final bool canSubmit;
  final bool isSaving;
  final List<String> skills;
  final List<CurriculumItem> experiences;
  final List<CurriculumItem> education;
  final String? errorMessage;
  final CurriculumFormNotice? notice;
  final String? noticeMessage;

  @override
  List<Object?> get props => [
    viewStatus,
    hasChanges,
    canSubmit,
    isSaving,
    skills,
    experiences,
    education,
    errorMessage,
    notice,
    noticeMessage,
  ];

  CurriculumFormState copyWith({
    CurriculumFormViewStatus? viewStatus,
    bool? hasChanges,
    bool? canSubmit,
    bool? isSaving,
    List<String>? skills,
    List<CurriculumItem>? experiences,
    List<CurriculumItem>? education,
    String? errorMessage,
    CurriculumFormNotice? notice,
    String? noticeMessage,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return CurriculumFormState(
      viewStatus: viewStatus ?? this.viewStatus,
      hasChanges: hasChanges ?? this.hasChanges,
      canSubmit: canSubmit ?? this.canSubmit,
      isSaving: isSaving ?? this.isSaving,
      skills: skills ?? this.skills,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }
}

class CurriculumFormCubit extends Cubit<CurriculumFormState> {
  CurriculumFormCubit({required CurriculumCubit curriculumCubit})
    : _curriculumCubit = curriculumCubit,
      headlineController = TextEditingController(),
      summaryController = TextEditingController(),
      phoneController = TextEditingController(),
      locationController = TextEditingController(),
      super(const CurriculumFormState()) {
    headlineController.addListener(_handleTextChanged);
    summaryController.addListener(_handleTextChanged);
    phoneController.addListener(_handleTextChanged);
    locationController.addListener(_handleTextChanged);
    _subscription = _curriculumCubit.stream.listen(_syncFromCurriculum);
    _syncFromCurriculum(_curriculumCubit.state);
  }

  final CurriculumCubit _curriculumCubit;
  final TextEditingController headlineController;
  final TextEditingController summaryController;
  final TextEditingController phoneController;
  final TextEditingController locationController;

  StreamSubscription<CurriculumState>? _subscription;
  Curriculum _initial = Curriculum.empty();
  CurriculumStatus? _lastStatus;

  void refresh() => _curriculumCubit.refresh();

  void clearNotice() {
    if (state.notice != null) emit(state.copyWith(clearNotice: true));
  }

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final updated = [...state.skills];
    if (updated.any((s) => s.toLowerCase() == trimmed.toLowerCase())) return;
    updated.add(trimmed);
    _emitListUpdate(skills: updated);
  }

  void removeSkill(String skill) {
    _emitListUpdate(
      skills: state.skills.where((s) => s != skill).toList(),
    );
  }

  void addExperience(CurriculumItem item) {
    _emitListUpdate(experiences: [...state.experiences, item]);
  }

  void updateExperience(int index, CurriculumItem item) {
    if (index < 0 || index >= state.experiences.length) return;
    final next = [...state.experiences];
    next[index] = item;
    _emitListUpdate(experiences: next);
  }

  void removeExperience(int index) {
    if (index < 0 || index >= state.experiences.length) return;
    final next = [...state.experiences]..removeAt(index);
    _emitListUpdate(experiences: next);
  }

  void addEducation(CurriculumItem item) {
    _emitListUpdate(education: [...state.education, item]);
  }

  void updateEducation(int index, CurriculumItem item) {
    if (index < 0 || index >= state.education.length) return;
    final next = [...state.education];
    next[index] = item;
    _emitListUpdate(education: next);
  }

  void removeEducation(int index) {
    if (index < 0 || index >= state.education.length) return;
    final next = [...state.education]..removeAt(index);
    _emitListUpdate(education: next);
  }

  void submit() {
    if (!state.canSubmit) return;
    _curriculumCubit.save(
      Curriculum(
        headline: headlineController.text.trim(),
        summary: summaryController.text.trim(),
        phone: phoneController.text.trim(),
        location: locationController.text.trim(),
        skills: state.skills,
        experiences: state.experiences,
        education: state.education,
        updatedAt: _curriculumCubit.state.curriculum?.updatedAt,
      ),
    );
  }

  void _emitListUpdate({
    List<String>? skills,
    List<CurriculumItem>? experiences,
    List<CurriculumItem>? education,
  }) {
    final nextSkills = skills ?? state.skills;
    final nextExperiences = experiences ?? state.experiences;
    final nextEducation = education ?? state.education;
    final hasChanges = _computeHasChanges(
      headline: headlineController.text.trim(),
      summary: summaryController.text.trim(),
      phone: phoneController.text.trim(),
      location: locationController.text.trim(),
      skills: nextSkills,
      experiences: nextExperiences,
      education: nextEducation,
    );
    final canSubmit = _canSubmit(hasChanges, state.isSaving);
    emit(
      state.copyWith(
        skills: nextSkills,
        experiences: nextExperiences,
        education: nextEducation,
        hasChanges: hasChanges,
        canSubmit: canSubmit,
      ),
    );
  }

  void _handleTextChanged() {
    final hasChanges = _computeHasChanges(
      headline: headlineController.text.trim(),
      summary: summaryController.text.trim(),
      phone: phoneController.text.trim(),
      location: locationController.text.trim(),
      skills: state.skills,
      experiences: state.experiences,
      education: state.education,
    );
    final canSubmit = _canSubmit(hasChanges, state.isSaving);
    if (hasChanges != state.hasChanges || canSubmit != state.canSubmit) {
      emit(state.copyWith(hasChanges: hasChanges, canSubmit: canSubmit));
    }
  }

  void _syncFromCurriculum(CurriculumState curriculumState) {
    final curriculum = curriculumState.curriculum;
    final viewStatus = _resolveViewStatus(curriculumState);
    final isSaving = curriculumState.status == CurriculumStatus.saving;
    final justSaved =
        _lastStatus == CurriculumStatus.saving &&
        curriculumState.status == CurriculumStatus.loaded;

    if (viewStatus == CurriculumFormViewStatus.ready &&
        curriculum != null &&
        !state.hasChanges) {
      _initial = curriculum;
      headlineController.text = curriculum.headline;
      summaryController.text = curriculum.summary;
      phoneController.text = curriculum.phone;
      locationController.text = curriculum.location;
    }

    var next = state.copyWith(
      viewStatus: viewStatus,
      isSaving: isSaving,
      skills: curriculum?.skills ?? const [],
      experiences: curriculum?.experiences ?? const [],
      education: curriculum?.education ?? const [],
      hasChanges: justSaved ? false : state.hasChanges,
      canSubmit: justSaved
          ? false
          : _canSubmit(state.hasChanges, isSaving),
      errorMessage: viewStatus == CurriculumFormViewStatus.error
          ? curriculumState.errorMessage
          : null,
      clearError: viewStatus != CurriculumFormViewStatus.error,
    );

    final noticeUpdate = _resolveNotice(curriculumState);
    if (noticeUpdate != null) {
      next = next.copyWith(
        notice: noticeUpdate.notice,
        noticeMessage: noticeUpdate.message,
      );
    }

    _lastStatus = curriculumState.status;
    emit(next);
  }

  CurriculumFormViewStatus _resolveViewStatus(CurriculumState curriculumState) {
    if (curriculumState.status == CurriculumStatus.empty) {
      return CurriculumFormViewStatus.empty;
    }
    if (curriculumState.status == CurriculumStatus.loading &&
        curriculumState.curriculum == null) {
      return CurriculumFormViewStatus.loading;
    }
    if (curriculumState.status == CurriculumStatus.failure &&
        curriculumState.curriculum == null) {
      return CurriculumFormViewStatus.error;
    }
    return CurriculumFormViewStatus.ready;
  }

  _NoticeUpdate? _resolveNotice(CurriculumState curriculumState) {
    if (_lastStatus == CurriculumStatus.saving &&
        curriculumState.status == CurriculumStatus.loaded) {
      _initial = curriculumState.curriculum ?? _initial;
      return _NoticeUpdate(
        notice: CurriculumFormNotice.success,
        message: 'Curriculum actualizado.',
      );
    }
    if (curriculumState.status == CurriculumStatus.failure &&
        curriculumState.errorMessage != null) {
      return _NoticeUpdate(
        notice: CurriculumFormNotice.error,
        message: curriculumState.errorMessage!,
      );
    }
    return null;
  }

  bool _computeHasChanges({
    required String headline,
    required String summary,
    required String phone,
    required String location,
    required List<String> skills,
    required List<CurriculumItem> experiences,
    required List<CurriculumItem> education,
  }) {
    return headline != _initial.headline ||
        summary != _initial.summary ||
        phone != _initial.phone ||
        location != _initial.location ||
        !_sameList(skills, _initial.skills) ||
        !_sameItems(experiences, _initial.experiences) ||
        !_sameItems(education, _initial.education);
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _sameItems(List<CurriculumItem> a, List<CurriculumItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.title != right.title ||
          left.subtitle != right.subtitle ||
          left.period != right.period ||
          left.description != right.description) {
        return false;
      }
    }
    return true;
  }

  bool _canSubmit(bool hasChanges, bool isSaving) {
    return hasChanges && !isSaving && headlineController.text.trim().isNotEmpty;
  }

  @override
  Future<void> close() {
    headlineController.removeListener(_handleTextChanged);
    summaryController.removeListener(_handleTextChanged);
    phoneController.removeListener(_handleTextChanged);
    locationController.removeListener(_handleTextChanged);
    headlineController.dispose();
    summaryController.dispose();
    phoneController.dispose();
    locationController.dispose();
    _subscription?.cancel();
    return super.close();
  }
}

class _NoticeUpdate {
  _NoticeUpdate({required this.notice, required this.message});

  final CurriculumFormNotice notice;
  final String message;
}

