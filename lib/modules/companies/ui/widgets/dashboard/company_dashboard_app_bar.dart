import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

class CompanyDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CompanyDashboardAppBar({
    super.key,
    required this.showAccountActions,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.accountMenu,
  });

  final bool showAccountActions;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    final actions = showAccountActions
        ? <Widget>[
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDarkMode ? 'Modo claro' : 'Modo oscuro',
              onPressed: onToggleTheme,
            ),
            if (accountMenu != null) accountMenu!,
          ]
        : null;

    return CoreShellAppBar(
      variant: CoreShellVariant.company,
      title: 'OPTIJOB',
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
