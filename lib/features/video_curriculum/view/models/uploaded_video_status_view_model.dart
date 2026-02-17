import 'package:equatable/equatable.dart';

class UploadedVideoStatusViewModel extends Equatable {
  const UploadedVideoStatusViewModel({
    required this.hasUploadedVideo,
    required this.title,
    required this.description,
    required this.storagePath,
    this.sizeLabel,
  });

  final bool hasUploadedVideo;
  final String title;
  final String description;
  final String storagePath;
  final String? sizeLabel;

  @override
  List<Object?> get props => [
    hasUploadedVideo,
    title,
    description,
    storagePath,
    sizeLabel,
  ];
}
