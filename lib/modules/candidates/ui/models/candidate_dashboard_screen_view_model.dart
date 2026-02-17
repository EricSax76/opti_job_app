import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class CandidateDashboardBottomNavItemViewModel extends Equatable {
  const CandidateDashboardBottomNavItemViewModel({
    required this.index,
    required this.icon,
    required this.label,
    required this.showsInterviewsBadge,
  });

  final int index;
  final IconData icon;
  final String label;
  final bool showsInterviewsBadge;

  @override
  List<Object> get props => [index, icon, label, showsInterviewsBadge];
}

class CandidateDashboardScreenViewModel extends Equatable {
  const CandidateDashboardScreenViewModel({
    required this.selectedIndex,
    required this.avatarUrl,
    required this.showNavigationSidebar,
    required this.bottomNavigationItems,
    required this.selectedBottomNavigationPosition,
  });

  final int selectedIndex;
  final String? avatarUrl;
  final bool showNavigationSidebar;
  final List<CandidateDashboardBottomNavItemViewModel> bottomNavigationItems;
  final int selectedBottomNavigationPosition;

  bool get showBottomNavigationBar =>
      !showNavigationSidebar && bottomNavigationItems.isNotEmpty;

  bool get showDrawer => !showNavigationSidebar;

  @override
  List<Object?> get props => [
    selectedIndex,
    avatarUrl,
    showNavigationSidebar,
    bottomNavigationItems,
    selectedBottomNavigationPosition,
  ];
}
