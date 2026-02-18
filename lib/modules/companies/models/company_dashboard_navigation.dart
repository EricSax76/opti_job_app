import 'package:flutter/material.dart';

import 'package:opti_job_app/core/config/feature_flags.dart';

class CompanyDashboardNavItem {
  const CompanyDashboardNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.routeSuffix,
  });

  final int index;
  final String label;
  final IconData icon;
  final String routeSuffix;
}

const _companyDashboardBaseItems = <CompanyDashboardNavItem>[
  CompanyDashboardNavItem(
    index: 0,
    label: 'Home',
    icon: Icons.home_outlined,
    routeSuffix: 'dashboard',
  ),
  CompanyDashboardNavItem(
    index: 1,
    label: 'Publicar oferta',
    icon: Icons.add_circle_outline,
    routeSuffix: 'publish-offer',
  ),
  CompanyDashboardNavItem(
    index: 2,
    label: 'Mis ofertas',
    icon: Icons.work_outline,
    routeSuffix: 'offers',
  ),
  CompanyDashboardNavItem(
    index: 3,
    label: 'Candidatos',
    icon: Icons.people_outline,
    routeSuffix: 'candidates',
  ),
];

const _companyDashboardInterviewsItem = CompanyDashboardNavItem(
  index: 4,
  label: 'Entrevistas',
  icon: Icons.chat_bubble_outline,
  routeSuffix: 'interviews',
);

List<CompanyDashboardNavItem> companyDashboardNavItems({
  bool interviewsEnabled = FeatureFlags.interviews,
}) {
  if (!interviewsEnabled) return _companyDashboardBaseItems;
  return <CompanyDashboardNavItem>[
    ..._companyDashboardBaseItems,
    _companyDashboardInterviewsItem,
  ];
}

int companyDashboardMaxIndex({bool interviewsEnabled = FeatureFlags.interviews}) {
  final items = companyDashboardNavItems(interviewsEnabled: interviewsEnabled);
  if (items.isEmpty) return 0;
  return items.last.index;
}

int companyDashboardClampIndex(
  int index, {
  bool interviewsEnabled = FeatureFlags.interviews,
}) {
  if (index < 0) return 0;
  final maxIndex = companyDashboardMaxIndex(
    interviewsEnabled: interviewsEnabled,
  );
  if (index > maxIndex) return maxIndex;
  return index;
}

CompanyDashboardNavItem companyDashboardItemForIndex(
  int index, {
  bool interviewsEnabled = FeatureFlags.interviews,
}) {
  final items = companyDashboardNavItems(interviewsEnabled: interviewsEnabled);
  return items.firstWhere(
    (item) => item.index == index,
    orElse: () => items.first,
  );
}

String? companyDashboardPathForIndex({
  required String uid,
  required int index,
  bool interviewsEnabled = FeatureFlags.interviews,
}) {
  final normalizedUid = uid.trim();
  if (normalizedUid.isEmpty) return null;
  final item = companyDashboardItemForIndex(
    index,
    interviewsEnabled: interviewsEnabled,
  );
  return '/company/$normalizedUid/${item.routeSuffix}';
}
