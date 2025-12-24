import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const divider = Color(0xFFE2E8F0);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      shape: const Border(bottom: BorderSide(color: divider, width: 1)),
      title: Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/CandidateLogin'),
          child: const Text('Candidato'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/job-offer'),
          child: const Text('Ofertas'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/CompanyLogin'),
          child: const Text('Empresa'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
