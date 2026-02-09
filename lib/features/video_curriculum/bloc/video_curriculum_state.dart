part of 'video_curriculum_bloc.dart';

enum VideoCurriculumStatus { initial, recording, uploading, success, failure }

class VideoCurriculumState extends Equatable {
  static const Object _unset = Object();

  const VideoCurriculumState({
    this.status = VideoCurriculumStatus.initial,
    this.attemptsLeft = 3,
    this.recordedVideoPath,
    this.error,
  });

  final VideoCurriculumStatus status;
  final int attemptsLeft;
  final String? recordedVideoPath;
  final String? error;

  VideoCurriculumState copyWith({
    VideoCurriculumStatus? status,
    int? attemptsLeft,
    Object? recordedVideoPath = _unset,
    String? Function()? error,
  }) {
    return VideoCurriculumState(
      status: status ?? this.status,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      recordedVideoPath: recordedVideoPath == _unset
          ? this.recordedVideoPath
          : recordedVideoPath as String?,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [status, attemptsLeft, recordedVideoPath, error];
}
