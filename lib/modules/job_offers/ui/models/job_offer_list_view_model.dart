import 'package:equatable/equatable.dart';

class JobOfferListItemViewModel extends Equatable {
  const JobOfferListItemViewModel({
    required this.offerId,
    required this.title,
    required this.companyName,
    this.avatarUrl,
    this.salary,
    this.modality,
  });

  final String offerId;
  final String title;
  final String companyName;
  final String? avatarUrl;
  final String? salary;
  final String? modality;

  @override
  List<Object?> get props => [
    offerId,
    title,
    companyName,
    avatarUrl,
    salary,
    modality,
  ];
}

class JobOfferListViewModel extends Equatable {
  const JobOfferListViewModel({
    required this.items,
    required this.availableJobTypes,
    required this.selectedJobType,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final List<JobOfferListItemViewModel> items;
  final List<String> availableJobTypes;
  final String? selectedJobType;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [
    items,
    availableJobTypes,
    selectedJobType,
    isRefreshing,
    isLoadingMore,
    hasMore,
  ];
}
