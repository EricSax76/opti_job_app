import 'package:flutter/material.dart';

class CandidateDashboardNavItem {
  const CandidateDashboardNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.routeSuffix,
    this.tabLabel,
    this.tabIcon,
    this.drawerLabel,
    this.showInTabs = false,
    this.showInDrawer = false,
    this.showInSidebar = true,
  });

  final int index;
  final String label;
  final IconData icon;
  final String routeSuffix;
  final String? tabLabel;
  final IconData? tabIcon;
  final String? drawerLabel;
  final bool showInTabs;
  final bool showInDrawer;
  final bool showInSidebar;
}

const candidateDashboardSidebarBreakpoint = 900.0;

const candidateDashboardNavItems = <CandidateDashboardNavItem>[
  CandidateDashboardNavItem(
    index: 0,
    label: 'Para ti (inicio)',
    icon: Icons.dashboard_outlined,
    routeSuffix: 'dashboard',
    tabLabel: 'Para ti',
    tabIcon: Icons.dashboard,
    showInTabs: true,
  ),
  CandidateDashboardNavItem(
    index: 1,
    label: 'Mis ofertas',
    icon: Icons.work_outline,
    routeSuffix: 'applications',
    tabLabel: 'Mis Ofertas',
    tabIcon: Icons.work_history,
    showInTabs: true,
  ),
  CandidateDashboardNavItem(
    index: 2,
    label: 'Entrevistas',
    icon: Icons.event_available_outlined,
    routeSuffix: 'interviews',
    tabLabel: 'Entrevistas',
    tabIcon: Icons.event_available_outlined,
    showInTabs: true,
  ),
  CandidateDashboardNavItem(
    index: 3,
    label: 'CV',
    icon: Icons.description_outlined,
    routeSuffix: 'cv',
    showInDrawer: true,
  ),
  CandidateDashboardNavItem(
    index: 4,
    label: 'Carta de presentación',
    icon: Icons.mail_outline,
    routeSuffix: 'cover-letter',
    showInDrawer: true,
  ),
  CandidateDashboardNavItem(
    index: 5,
    label: 'Video CV',
    icon: Icons.videocam_outlined,
    routeSuffix: 'video-cv',
    drawerLabel: 'Video curriculum',
    showInDrawer: true,
  ),
];

final List<CandidateDashboardNavItem> candidateDashboardTabItems =
    List.unmodifiable(
  candidateDashboardNavItems.where((item) => item.showInTabs),
);

final List<CandidateDashboardNavItem> candidateDashboardDrawerItems =
    List.unmodifiable(
  candidateDashboardNavItems.where((item) => item.showInDrawer),
);

final List<CandidateDashboardNavItem> candidateDashboardSidebarItems =
    List.unmodifiable(
  candidateDashboardNavItems.where((item) => item.showInSidebar),
);

int get candidateDashboardMaxIndex => candidateDashboardNavItems.fold<int>(
      0,
      (maxIndex, item) => item.index > maxIndex ? item.index : maxIndex,
    );

int candidateDashboardClampIndex(int index) {
  if (index < 0) return 0;
  if (index > candidateDashboardMaxIndex) return candidateDashboardMaxIndex;
  return index;
}

int candidateDashboardClampTabIndex(int index) {
  if (candidateDashboardTabItems.isEmpty) return 0;
  final maxTabIndex = candidateDashboardTabItems.length - 1;
  if (index < 0) return 0;
  if (index > maxTabIndex) return maxTabIndex;
  return index;
}

bool candidateDashboardIsTabIndex(int index) =>
    index >= 0 && index < candidateDashboardTabItems.length;

int candidateDashboardNavIndexForTabIndex(int tabIndex) =>
    candidateDashboardTabItems[tabIndex].index;

CandidateDashboardNavItem candidateDashboardItemForIndex(int index) =>
    candidateDashboardNavItems.firstWhere(
      (item) => item.index == index,
      orElse: () => candidateDashboardNavItems.first,
    );

String? candidateDashboardPathForIndex({
  required String uid,
  required int index,
}) {
  if (uid.isEmpty) return null;
  final item = candidateDashboardItemForIndex(index);
  return '/candidate/$uid/${item.routeSuffix}';
}
