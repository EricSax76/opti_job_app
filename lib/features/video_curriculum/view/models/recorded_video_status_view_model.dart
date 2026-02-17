import 'package:equatable/equatable.dart';

class RecordedVideoStatusViewModel extends Equatable {
  const RecordedVideoStatusViewModel({
    required this.hasRecordedVideo,
    required this.title,
    required this.description,
    required this.playbackUri,
  });

  final bool hasRecordedVideo;
  final String title;
  final String description;
  final Uri? playbackUri;

  bool get canPlay => playbackUri != null;

  @override
  List<Object?> get props => [
    hasRecordedVideo,
    title,
    description,
    playbackUri,
  ];
}
