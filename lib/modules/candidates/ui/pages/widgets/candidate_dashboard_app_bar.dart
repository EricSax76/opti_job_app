import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_interviews_badge.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';

class CandidateDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CandidateDashboardAppBar({
    super.key,
    required this.tabController,
    required this.avatarUrl,
    required this.onOpenProfile,
    required this.onLogout,
    required this.showTabBar,
  });

  final TabController tabController;
  final String? avatarUrl;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;
  final bool showTabBar;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (showTabBar ? kTextTabBarHeight : 0) + (kIsWeb ? 12 : 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobileLayout =
        MediaQuery.sizeOf(context).width < candidateDashboardSidebarBreakpoint;
    final avatarImageCacheSize = (32 * MediaQuery.of(context).devicePixelRatio)
        .round();
    final toolbarHeight = kToolbarHeight + (kIsWeb ? 12 : 0);
    final avatarRadius = isMobileLayout ? 16.0 : 18.0;
    final avatarDiameter = avatarRadius * 2;

    final accountMenu = PopupMenuButton<_CandidateAccountAction>(
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
      child: isMobileLayout
          ? CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colorScheme.secondaryContainer,
              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        width: avatarDiameter,
                        height: avatarDiameter,
                        fit: BoxFit.cover,
                        cacheWidth: avatarImageCacheSize,
                        cacheHeight: avatarImageCacheSize,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 20,
                            color: colorScheme.onSecondaryContainer,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!showTabBar) ...[
                    Text(
                      'Mi Cuenta',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              avatarUrl!,
                              width: avatarDiameter,
                              height: avatarDiameter,
                              fit: BoxFit.cover,
                              cacheWidth: avatarImageCacheSize,
                              cacheHeight: avatarImageCacheSize,
                              filterQuality: FilterQuality.low,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 20,
                                  color: colorScheme.onSecondaryContainer,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 20,
                            color: colorScheme.onSecondaryContainer,
                          ),
                  ),
                ],
              ),
            ),
    );

    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth: isMobileLayout ? kToolbarHeight : null,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: showTabBar
          ? null
          : Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
      title: Text(
        'OPTIJOB',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: colorScheme.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!showTabBar && !isMobileLayout)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
          ),
        if (!showTabBar && !isMobileLayout) const SizedBox(width: 8),
        if (isMobileLayout)
          SizedBox(
            width: kToolbarHeight,
            child: Center(child: accountMenu),
          )
        else
          accountMenu,
      ],
      bottom: showTabBar
          ? TabBar(
              controller: tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabAlignment: TabAlignment.center,
              isScrollable: true,
              dividerColor: Colors.transparent,
              tabs: [
                for (final item in candidateDashboardTabItems)
                  if (item.label != 'Entrevistas' || FeatureFlags.interviews)
                    Tab(
                      icon: item.index == 2
                          ? CandidateInterviewsBadge(
                              child: Icon(item.tabIcon ?? item.icon),
                            )
                          : Icon(item.tabIcon ?? item.icon),
                      text: item.tabLabel ?? item.label,
                    ),
              ],
            )
          : null,
    );
  }
}

enum _CandidateAccountAction { profile, logout }
