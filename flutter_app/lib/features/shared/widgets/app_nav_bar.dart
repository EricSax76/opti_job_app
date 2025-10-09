import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;

    void goTo(String location) {
      context.go(location);
    }

    final actionButtons = <Widget>[
      TextButton(
        onPressed: () => goTo('/CandidateLogin'),
        child: const Text('Candidato'),
      ),
      TextButton(
        onPressed: () => goTo('/job-offer'),
        child: const Text('Ofertas'),
      ),
      TextButton(
        onPressed: () => goTo('/CompanyLogin'),
        child: const Text('Empresa'),
      ),
    ];

    return AppBar(
      title: const Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: isCompact
          ? [
              PopupMenuButton<String>(
                onSelected: goTo,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: '/CandidateLogin',
                    child: Text('Candidato'),
                  ),
                  PopupMenuItem(
                    value: '/job-offer',
                    child: Text('Ofertas'),
                  ),
                  PopupMenuItem(
                    value: '/CompanyLogin',
                    child: Text('Empresa'),
                  ),
                ],
              ),
            ]
          : actionButtons
              .map(
                (button) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: button,
                ),
              )
              .toList(),
    );
  }
}
