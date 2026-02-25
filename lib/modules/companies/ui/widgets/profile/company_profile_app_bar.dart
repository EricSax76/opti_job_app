import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

class CompanyProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CompanyProfileAppBar({
    super.key,
    required this.showActions,
    required this.showLogoutAction,
    this.onLogout,
    this.accountMenu,
  });

  final bool showActions;
  final bool showLogoutAction;
  final VoidCallback? onLogout;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    final actions = showActions
        ? <Widget>[
            ?accountMenu,
            if (showLogoutAction && onLogout != null)
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
          ]
        : null;

    return CoreShellAppBar(
      variant: CoreShellVariant.company,
      title: 'Perfil',
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
