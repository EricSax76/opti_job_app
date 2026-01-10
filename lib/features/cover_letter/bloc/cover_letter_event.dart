part of 'cover_letter_bloc.dart';

abstract class CoverLetterEvent extends Equatable {
  const CoverLetterEvent();

  @override
  List<Object> get props => [];
}

class LoadCoverLetterRequested extends CoverLetterEvent {}

class VideoRecordingStarted extends CoverLetterEvent {}

class VideoRecordingStopped extends CoverLetterEvent {
  const VideoRecordingStopped(this.path);
  final String path;

  @override
  List<Object> get props => [path];
}

class RetryVideoRecording extends CoverLetterEvent {}

class ImproveCoverLetterRequested extends CoverLetterEvent {
  const ImproveCoverLetterRequested(this.originalText, {required this.locale});
  final String originalText;
  final String locale;

  @override
  List<Object> get props => [originalText, locale];
}

class SaveCoverLetterAndVideo extends CoverLetterEvent {
  const SaveCoverLetterAndVideo(this.coverLetterText);
  final String coverLetterText;

  @override
  List<Object> get props => [coverLetterText];
}
