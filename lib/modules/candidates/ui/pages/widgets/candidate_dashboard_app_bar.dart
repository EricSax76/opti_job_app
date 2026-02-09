import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';

class CandidateDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CandidateDashboardAppBar({
    super.key,
    required this.tabController,
    required this.avatarUrl,
    required this.onOpenProfile,
    required this.onLogout,
  });

  final TabController tabController;
  final String? avatarUrl;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarImageCacheSize = (32 * MediaQuery.of(context).devicePixelRatio)
        .round();

    return AppBar(
      title: const Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
      automaticallyImplyLeading: true,
      centerTitle: true,
      actions: [
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final isDark = themeState.themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            );
          },
        ),
        PopupMenuButton<_CandidateAccountAction>(
          tooltip: 'Cuenta',
          onSelected: (action) {
            switch (action) {
              case _CandidateAccountAction.profile:
                onOpenProfile();
                break;
              case _CandidateAccountAction.logout:
                onLogout();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _CandidateAccountAction.profile,
              child: Text('Mi perfil'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: _CandidateAccountAction.logout,
              child: Text('Cerrar sesión'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surface,
              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        cacheWidth: avatarImageCacheSize,
                        cacheHeight: avatarImageCacheSize,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_outline,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: tabController,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.secondary,
        tabs: [
          for (final item in candidateDashboardTabItems)
            Tab(
              icon: Icon(item.tabIcon ?? item.icon),
              text: item.tabLabel ?? item.label,
            ),
        ],
      ),
    );
  }
}

enum _CandidateAccountAction { profile, logout }
