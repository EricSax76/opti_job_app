import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_state.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_state.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/services/cv_analysis_service.dart';

export 'curriculum_form_state.dart';

class CurriculumFormCubit extends Cubit<CurriculumFormState> {
  CurriculumFormCubit({
    required CurriculumCubit curriculumCubit,
    CvAnalysisService? analysisService,
  })  : _curriculumCubit = curriculumCubit,
        _analysisService = analysisService ?? CvAnalysisService(),
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
  final CvAnalysisService _analysisService;
  final TextEditingController headlineController;
  final TextEditingController summaryController;
  final TextEditingController phoneController;
  final TextEditingController locationController;

  StreamSubscription<CurriculumState>? _subscription;
  Curriculum _initial = Curriculum.empty();
  CurriculumStatus? _lastStatus;
  var _isHydratingControllers = false;

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
    _emitListUpdate(skills: state.skills.where((s) => s != skill).toList());
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

  Future<void> analyzeCvFile(Uint8List bytes, String fileName) async {
    emit(state.copyWith(isAnalyzing: true, clearNotice: true));

    try {
      final result = await _analysisService.analyzeCvFile(bytes, fileName);

      if (result.summary.isNotEmpty) summaryController.text = result.summary;
      if (result.phone.isNotEmpty) phoneController.text = result.phone;
      if (result.location.isNotEmpty) locationController.text = result.location;

      _emitListUpdate(
        skills: result.skills.isNotEmpty ? result.skills : null,
        experiences: result.experiences.isNotEmpty ? result.experiences : null,
        education: result.education.isNotEmpty ? result.education : null,
      );

      emit(
        state.copyWith(
          isAnalyzing: false,
          notice: CurriculumFormNotice.success,
          noticeMessage: 'Datos extraídos correctamente.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isAnalyzing: false,
          notice: CurriculumFormNotice.error,
          noticeMessage: e.toString(),
        ),
      );
    }
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
    if (_isHydratingControllers) return;
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

    final shouldPreserveDraft = state.hasChanges && !justSaved;
    final nextSkills =
        shouldPreserveDraft ? state.skills : (curriculum?.skills ?? const []);
    final nextExperiences = shouldPreserveDraft
        ? state.experiences
        : (curriculum?.experiences ?? const []);
    final nextEducation = shouldPreserveDraft
        ? state.education
        : (curriculum?.education ?? const []);

    final shouldHydrateFromCurriculum =
        viewStatus == CurriculumFormViewStatus.ready &&
        curriculum != null &&
        !shouldPreserveDraft;

    if (shouldHydrateFromCurriculum) {
      _initial = curriculum;
      _isHydratingControllers = true;
      headlineController.text = curriculum.headline;
      summaryController.text = curriculum.summary;
      phoneController.text = curriculum.phone;
      locationController.text = curriculum.location;
      _isHydratingControllers = false;
    }

    final nextHasChanges = justSaved ? false : state.hasChanges;
    var next = state.copyWith(
      viewStatus: viewStatus,
      isSaving: isSaving,
      skills: nextSkills,
      experiences: nextExperiences,
      education: nextEducation,
      hasChanges: nextHasChanges,
      canSubmit: _canSubmit(nextHasChanges, isSaving),
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
    final currentRevision = Curriculum(
      headline: headline,
      summary: summary,
      phone: phone,
      location: location,
      skills: skills,
      experiences: experiences,
      education: education,
      attachment: _initial.attachment,
      updatedAt: _initial.updatedAt,
    );
    return currentRevision != _initial;
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
