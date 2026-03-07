import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class LandingDrawer extends StatelessWidget {
  const LandingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(uiSpacing24),
              child: Text('OPTIJOB', style: titleStyle),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.home_outlined,
              label: l10n.navHome,
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
            _DrawerItem(
              icon: Icons.business_outlined,
              label: l10n.navCompanies,
              onTap: () {
                Navigator.pop(context);
                context.go('/para-empresas');
              },
            ),
            _DrawerItem(
              icon: Icons.people_outline,
              label: l10n.navRecruiters,
              onTap: () {
                Navigator.pop(context);
                context.go('/para-recruiters');
              },
            ),
            _DrawerItem(
              icon: Icons.grid_view_outlined,
              label: l10n.navFeatures,
              onTap: () {
                Navigator.pop(context);
                context.go('/funcionalidades');
              },
            ),
            _DrawerItem(
              icon: Icons.work_outline,
              label: l10n.navOffers,
              onTap: () {
                Navigator.pop(context);
                context.go('/job-offer');
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(uiSpacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/CandidateLogin');
                    },
                    child: Text(l10n.heroCandidateCta),
                  ),
                  const SizedBox(height: uiSpacing8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/CompanyLogin');
                    },
                    child: Text(l10n.heroCompanyCta),
                  ),
                  const SizedBox(height: uiSpacing8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/recruiter-login');
                    },
                    child: Text(l10n.heroRecruiterCta),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
