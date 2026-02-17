import 'package:equatable/equatable.dart';

class VideoCurriculumViewModel extends Equatable {
  const VideoCurriculumViewModel({required this.hasRecordedVideo});

  final bool hasRecordedVideo;

  @override
  List<Object> get props => [hasRecordedVideo];
}
