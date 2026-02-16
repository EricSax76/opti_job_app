import 'package:flutter/material.dart';

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

    return AppBar(
      title: const Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
      automaticallyImplyLeading: false,
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
