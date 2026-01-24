import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

enum CurriculumFormViewStatus { loading, empty, error, ready }

enum CurriculumFormNotice { success, error }

class CurriculumFormState extends Equatable {
  const CurriculumFormState({
    this.viewStatus = CurriculumFormViewStatus.loading,
    this.hasChanges = false,
    this.canSubmit = false,
    this.isSaving = false,
    this.isAnalyzing = false,
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
  final bool isAnalyzing;
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
    isAnalyzing,
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
    bool? isAnalyzing,
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
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      skills: skills ?? this.skills,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }
}
