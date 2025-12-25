import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

enum CurriculumStatus { initial, loading, loaded, saving, failure, empty }

class CurriculumState extends Equatable {
  const CurriculumState({
    this.status = CurriculumStatus.initial,
    this.curriculum,
    this.errorMessage,
  });

  final CurriculumStatus status;
  final Curriculum? curriculum;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, curriculum, errorMessage];

  CurriculumState copyWith({
    CurriculumStatus? status,
    Curriculum? curriculum,
    String? errorMessage,
    bool clearCurriculum = false,
    bool clearError = false,
  }) {
    return CurriculumState(
      status: status ?? this.status,
      curriculum: clearCurriculum ? null : curriculum ?? this.curriculum,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

