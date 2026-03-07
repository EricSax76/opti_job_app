import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class LandingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LandingAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= uiBreakpointTablet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      color: theme.brightness == Brightness.dark
          ? colorScheme.onSurface
          : colorScheme.primary,
    );

    return AppBar(
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text('OPTIJOB', style: titleStyle),
      ),
      centerTitle: !isDesktop,
      automaticallyImplyLeading: false,
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: isDesktop
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      actions: isDesktop
          ? [
              _NavLink(
                label: l10n.navHome,
                onTap: () => context.go('/'),
              ),
              _NavLink(
                label: l10n.navCompanies,
                onTap: () => context.go('/para-empresas'),
              ),
              _NavLink(
                label: l10n.navRecruiters,
                onTap: () => context.go('/para-recruiters'),
              ),
              _NavLink(
                label: l10n.navFeatures,
                onTap: () => context.go('/funcionalidades'),
              ),
              const SizedBox(width: uiSpacing8),
              Padding(
                padding: const EdgeInsets.only(right: uiSpacing16),
                child: FilledButton(
                  onPressed: () => context.go('/CandidateLogin'),
                  child: Text(l10n.navLogin),
                ),
              ),
            ]
          : null,
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: uiSpacing12),
      ),
      child: Text(label),
    );
  }
}
