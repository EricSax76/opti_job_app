import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';

class CandidateDashboardDrawer extends StatelessWidget {
  const CandidateDashboardDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.surface),
            child: Center(
              child: Text(
                'OPTIJOB',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          for (final item in candidateDashboardDrawerItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.drawerLabel ?? item.label),
              selected: item.index == selectedIndex,
              onTap: () => onSelected(item.index),
            ),
        ],
      ),
    );
  }
}
