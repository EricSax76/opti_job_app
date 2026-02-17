import 'package:equatable/equatable.dart';

class CurriculumItemsSectionEntryViewModel extends Equatable {
  const CurriculumItemsSectionEntryViewModel({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final int index;
  final String title;
  final String subtitle;

  @override
  List<Object> get props => [index, title, subtitle];
}

class CurriculumItemsSectionViewModel extends Equatable {
  const CurriculumItemsSectionViewModel({
    required this.statusLabel,
    required this.entries,
  });

  final String statusLabel;
  final List<CurriculumItemsSectionEntryViewModel> entries;

  bool get isEmpty => entries.isEmpty;

  @override
  List<Object> get props => [statusLabel, entries];
}
