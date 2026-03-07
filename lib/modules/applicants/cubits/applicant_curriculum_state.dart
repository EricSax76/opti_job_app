part of 'applicant_curriculum_cubit.dart';

enum ApplicantCurriculumStatus { initial, loading, success, failure }

class ApplicantCurriculumState extends Equatable {
  const ApplicantCurriculumState({
    this.status = ApplicantCurriculumStatus.initial,
    this.candidate,
    this.curriculum,
    this.offer,
    this.isExporting = false,
    this.isMatching = false,
    this.hasVideoCurriculum = false,
    this.canViewVideoCurriculum = false,
    this.matchResult,
    this.errorMessage,
    this.infoMessage,
  });

  final ApplicantCurriculumStatus status;
  final Candidate? candidate;
  final Curriculum? curriculum;
  final JobOffer? offer;
  final bool isExporting;
  final bool isMatching;
  final bool hasVideoCurriculum;
  final bool canViewVideoCurriculum;
  final AiMatchResult? matchResult;
  final String? errorMessage;
  final String? infoMessage;

  ApplicantCurriculumState copyWith({
    ApplicantCurriculumStatus? status,
    Candidate? candidate,
    Curriculum? curriculum,
    JobOffer? offer,
    bool? isExporting,
    bool? isMatching,
    bool? hasVideoCurriculum,
    bool? canViewVideoCurriculum,
    AiMatchResult? matchResult,
    String? errorMessage,
    String? infoMessage,
    bool clearMatchResult = false,
    bool clearInfoMessage = false,
  }) {
    return ApplicantCurriculumState(
      status: status ?? this.status,
      candidate: candidate ?? this.candidate,
      curriculum: curriculum ?? this.curriculum,
      offer: offer ?? this.offer,
      isExporting: isExporting ?? this.isExporting,
      isMatching: isMatching ?? this.isMatching,
      hasVideoCurriculum: hasVideoCurriculum ?? this.hasVideoCurriculum,
      canViewVideoCurriculum:
          canViewVideoCurriculum ?? this.canViewVideoCurriculum,
      matchResult: clearMatchResult ? null : matchResult ?? this.matchResult,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    candidate,
    curriculum,
    offer,
    isExporting,
    isMatching,
    hasVideoCurriculum,
    canViewVideoCurriculum,
    matchResult,
    errorMessage,
    infoMessage,
  ];
}
