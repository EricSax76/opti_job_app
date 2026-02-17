import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return const CoreShellAppBar(
      variant: CoreShellVariant.public,
      title: 'OPTIJOB',
    );
  }
}
