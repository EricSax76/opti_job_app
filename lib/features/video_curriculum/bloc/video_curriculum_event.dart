part of 'video_curriculum_bloc.dart';

abstract class VideoCurriculumEvent extends Equatable {
  const VideoCurriculumEvent();

  @override
  List<Object> get props => [];
}

class VideoRecordingStarted extends VideoCurriculumEvent {}

class VideoRecordingStopped extends VideoCurriculumEvent {
  const VideoRecordingStopped(this.path);

  final String path;

  @override
  List<Object> get props => [path];
}

class RetryVideoRecording extends VideoCurriculumEvent {}

class SaveVideoCurriculumRequested extends VideoCurriculumEvent {
  const SaveVideoCurriculumRequested();
}
