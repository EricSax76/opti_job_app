import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= uiBreakpointTablet;
    final currentYear = DateTime.now().year;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant;
    final linkColor = colorScheme.onSurface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: uiSpacing32,
        horizontal: uiSpacing24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: uiBreakpointDesktop),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                _DesktopColumns(
                  l10n: l10n,
                  linkColor: linkColor,
                  mutedColor: mutedColor,
                )
              else
                _MobileColumns(
                  l10n: l10n,
                  linkColor: linkColor,
                  mutedColor: mutedColor,
                ),
              const SizedBox(height: uiSpacing24),
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: uiSpacing16),
              Center(
                child: Text(
                  l10n.footerCopyright(currentYear),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopColumns extends StatelessWidget {
  const _DesktopColumns({
    required this.l10n,
    required this.linkColor,
    required this.mutedColor,
  });

  final AppLocalizations l10n;
  final Color linkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FooterColumn(
            title: l10n.footerProductTitle,
            mutedColor: mutedColor,
            links: [
              _FooterLink(
                label: l10n.footerFeatures,
                route: '/funcionalidades',
              ),
              _FooterLink(
                label: l10n.footerForCompanies,
                route: '/para-empresas',
              ),
              _FooterLink(
                label: l10n.footerForRecruiters,
                route: '/para-recruiters',
              ),
            ],
            linkColor: linkColor,
          ),
        ),
        Expanded(
          child: _FooterColumn(
            title: l10n.footerLegalTitle,
            mutedColor: mutedColor,
            links: [
              _FooterLink(label: l10n.footerPrivacy),
              _FooterLink(label: l10n.footerTerms),
              _FooterLink(label: l10n.footerCookies),
            ],
            linkColor: linkColor,
          ),
        ),
        Expanded(
          child: _FooterColumn(
            title: l10n.footerCompanyTitle,
            mutedColor: mutedColor,
            links: [
              _FooterLink(label: l10n.footerAbout),
              _FooterLink(label: l10n.footerSupport),
            ],
            linkColor: linkColor,
          ),
        ),
      ],
    );
  }
}

class _MobileColumns extends StatelessWidget {
  const _MobileColumns({
    required this.l10n,
    required this.linkColor,
    required this.mutedColor,
  });

  final AppLocalizations l10n;
  final Color linkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FooterColumn(
          title: l10n.footerProductTitle,
          mutedColor: mutedColor,
          links: [
            _FooterLink(
              label: l10n.footerFeatures,
              route: '/funcionalidades',
            ),
            _FooterLink(
              label: l10n.footerForCompanies,
              route: '/para-empresas',
            ),
            _FooterLink(
              label: l10n.footerForRecruiters,
              route: '/para-recruiters',
            ),
          ],
          linkColor: linkColor,
        ),
        const SizedBox(height: uiSpacing24),
        _FooterColumn(
          title: l10n.footerLegalTitle,
          mutedColor: mutedColor,
          links: [
            _FooterLink(label: l10n.footerPrivacy),
            _FooterLink(label: l10n.footerTerms),
            _FooterLink(label: l10n.footerCookies),
          ],
          linkColor: linkColor,
        ),
        const SizedBox(height: uiSpacing24),
        _FooterColumn(
          title: l10n.footerCompanyTitle,
          mutedColor: mutedColor,
          links: [
            _FooterLink(label: l10n.footerAbout),
            _FooterLink(label: l10n.footerSupport),
          ],
          linkColor: linkColor,
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    required this.linkColor,
    required this.mutedColor,
  });

  final String title;
  final List<_FooterLink> links;
  final Color linkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: mutedColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: uiSpacing12),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: uiSpacing8),
            child: InkWell(
              onTap: link.route != null
                  ? () => context.go(link.route!)
                  : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  link.label,
                  style: TextStyle(
                    color: link.route != null ? linkColor : mutedColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLink {
  const _FooterLink({required this.label, this.route});

  final String label;
  final String? route;
}
