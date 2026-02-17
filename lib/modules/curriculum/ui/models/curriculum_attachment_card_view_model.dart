import 'package:equatable/equatable.dart';

class CurriculumAttachmentCardViewModel extends Equatable {
  const CurriculumAttachmentCardViewModel({
    required this.fileName,
    required this.metadataLabel,
  });

  final String fileName;
  final String metadataLabel;

  @override
  List<Object> get props => [fileName, metadataLabel];
}
