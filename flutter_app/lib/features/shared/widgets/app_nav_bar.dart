import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () => context.go('/CandidateLogin'),
          child: const Text('Candidato'),
        ),
        TextButton(
          onPressed: () => context.go('/job-offer'),
          child: const Text('Ofertas'),
        ),
        TextButton(
          onPressed: () => context.go('/CompanyLogin'),
          child: const Text('Empresa'),
        ),
      ],
    );
  }
}
