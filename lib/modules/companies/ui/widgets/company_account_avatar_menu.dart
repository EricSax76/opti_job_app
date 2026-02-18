import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/shell/core_shell_breakpoints.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';

enum CompanyAccountAction { profile, logout }

class CompanyAccountAvatarMenu extends StatelessWidget {
  const CompanyAccountAvatarMenu({super.key, this.showProfileOption = true});

  final bool showProfileOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final authCubit = context.read<CompanyAuthCubit>();

    final company = context.watch<CompanyAuthCubit>().state.company;
    final companyName = company?.name;
    final avatarUrl = company?.avatarUrl;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isMobileLayout = viewportWidth < coreShellNavigationBreakpoint;
    final showInlineAccountName = !isMobileLayout || kIsWeb;
    final accountNameMaxWidth = isMobileLayout ? 120.0 : 148.0;
    final avatarRadius = isMobileLayout ? 16.0 : 18.0;
    final avatarDiameter = avatarRadius * 2;

    return PopupMenuButton<CompanyAccountAction>(
      tooltip: 'Cuenta',
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case CompanyAccountAction.profile:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final router = _tryResolveRouter(context);
              router?.pushNamed('company-profile');
            });
            break;
          case CompanyAccountAction.logout:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authCubit.logout();
            });
            break;
        }
      },
      itemBuilder: (context) => [
        if (showProfileOption)
          const PopupMenuItem(
            value: CompanyAccountAction.profile,
            child: Text('Mi perfil'),
          ),
        if (showProfileOption) const PopupMenuDivider(),
        const PopupMenuItem(
          value: CompanyAccountAction.logout,
          child: Text('Cerrar sesión'),
        ),
      ],
      child: showInlineAccountName
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: accountNameMaxWidth),
                    child: Text(
                      _resolvedAccountLabel(companyName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CompanyAvatar(
                    avatarUrl: avatarUrl,
                    radius: avatarRadius,
                    diameter: avatarDiameter,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            )
          : _CompanyAvatar(
              avatarUrl: avatarUrl,
              radius: avatarRadius,
              diameter: avatarDiameter,
              colorScheme: colorScheme,
            ),
    );
  }

  static String _resolvedAccountLabel(String? companyName) {
    final trimmed = companyName?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Mi Cuenta';
    return trimmed;
  }

  GoRouter? _tryResolveRouter(BuildContext context) {
    try {
      return GoRouter.of(context);
    } catch (_) {
      return null;
    }
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({
    required this.avatarUrl,
    required this.radius,
    required this.diameter,
    required this.colorScheme,
  });

  final String? avatarUrl;
  final double radius;
  final double diameter;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.secondaryContainer,
      child: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  );
                },
              ),
            )
          : Icon(
              Icons.business_outlined,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
    );
  }
}
