import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class ApplicantReviewProfile extends Equatable {
  const ApplicantReviewProfile({
    required this.candidate,
    required this.curriculum,
    required this.revealLevel,
    required this.hasVideoCurriculum,
    required this.canViewVideoCurriculum,
  });

  final Candidate candidate;
  final Curriculum curriculum;
  final String revealLevel;
  final bool hasVideoCurriculum;
  final bool canViewVideoCurriculum;

  @override
  List<Object?> get props => [
    candidate,
    curriculum,
    revealLevel,
    hasVideoCurriculum,
    canViewVideoCurriculum,
  ];
}
