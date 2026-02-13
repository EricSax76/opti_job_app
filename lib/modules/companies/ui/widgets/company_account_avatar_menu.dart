import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';

enum CompanyAccountAction { profile, logout }

class CompanyAccountAvatarMenu extends StatelessWidget {
  const CompanyAccountAvatarMenu({super.key, this.showProfileOption = true});

  final bool showProfileOption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final router = GoRouter.of(context);
    final authCubit = context.read<CompanyAuthCubit>();

    final company = context.watch<CompanyAuthCubit>().state.company;
    final avatarUrl = company?.avatarUrl;

    return PopupMenuButton<CompanyAccountAction>(
      tooltip: 'Cuenta',
      onSelected: (action) {
        switch (action) {
          case CompanyAccountAction.profile:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              router.pushNamed('company-profile');
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.surface,
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Icon(
                  Icons.business_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}
