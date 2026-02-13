import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';

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
          const Divider(height: 1),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final isDark = themeState.themeMode == ThemeMode.dark;
              return ListTile(
                leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Tema oscuro'),
                subtitle: Text(isDark ? 'Activado' : 'Desactivado'),
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
