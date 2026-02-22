import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

class CompanyDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CompanyDashboardAppBar({
    super.key,
    required this.showAccountActions,
    required this.showMenuButton,
    this.accountMenu,
  });

  final bool showAccountActions;
  final bool showMenuButton;
  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    final mobileActionsRightInset = showMenuButton ? 20.0 : 0.0;
    final actions = showAccountActions
        ? <Widget>[
            if (accountMenu != null)
              Padding(
                padding: EdgeInsets.only(right: mobileActionsRightInset),
                child: accountMenu!,
              ),
          ]
        : null;

    return CoreShellAppBar(
      variant: CoreShellVariant.company,
      title: 'OPTIJOB',
      automaticallyImplyLeading: showMenuButton,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
