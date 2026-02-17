import 'package:equatable/equatable.dart';

class CurriculumReadOnlyContactViewModel extends Equatable {
  const CurriculumReadOnlyContactViewModel({
    required this.phone,
    required this.location,
  });

  final String? phone;
  final String? location;

  bool get hasPhone => phone != null;
  bool get hasLocation => location != null;
  bool get hasInfo => hasPhone || hasLocation;
  bool get showDivider => hasPhone && hasLocation;

  @override
  List<Object?> get props => [phone, location];
}

class CurriculumReadOnlyItemViewModel extends Equatable {
  const CurriculumReadOnlyItemViewModel({
    required this.title,
    this.subtitle,
    this.period,
    this.description,
  });

  final String title;
  final String? subtitle;
  final String? period;
  final String? description;

  bool get hasSubtitle => subtitle != null;
  bool get hasPeriod => period != null;
  bool get hasDescription => description != null;

  @override
  List<Object?> get props => [title, subtitle, period, description];
}

class CurriculumReadOnlyViewModel extends Equatable {
  const CurriculumReadOnlyViewModel({
    required this.headline,
    required this.summary,
    required this.contact,
    required this.skills,
    required this.experiences,
    required this.education,
    required this.attachmentFileName,
  });

  final String headline;
  final String summary;
  final CurriculumReadOnlyContactViewModel contact;
  final List<String> skills;
  final List<CurriculumReadOnlyItemViewModel> experiences;
  final List<CurriculumReadOnlyItemViewModel> education;
  final String? attachmentFileName;

  bool get hasHeadline => headline.isNotEmpty;
  bool get hasSummary => summary.isNotEmpty;
  bool get hasContactInfo => contact.hasInfo;
  bool get hasSkills => skills.isNotEmpty;
  bool get hasExperiences => experiences.isNotEmpty;
  bool get hasEducation => education.isNotEmpty;
  bool get hasAttachment => attachmentFileName != null;

  @override
  List<Object?> get props => [
    headline,
    summary,
    contact,
    skills,
    experiences,
    education,
    attachmentFileName,
  ];
}
