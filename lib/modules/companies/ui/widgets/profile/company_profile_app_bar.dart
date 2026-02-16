import 'package:flutter/material.dart';

class CompanyProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CompanyProfileAppBar({
    super.key,
    required this.borderColor,
    required this.showActions,
    required this.showLogoutAction,
    this.onLogout,
    this.accountMenu,
  });

  final Color borderColor;
  final bool showActions;
  final bool showLogoutAction;
  final VoidCallback? onLogout;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    final actions = showActions
        ? <Widget>[
            if (accountMenu != null) accountMenu!,
            if (showLogoutAction && onLogout != null)
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
              ),
          ]
        : null;

    return AppBar(
      title: const Text('Perfil'),
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
