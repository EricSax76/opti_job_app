import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    const ink = uiInk;
    const divider = uiBorder;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      shape: const Border(bottom: BorderSide(color: divider, width: 1)),
      title: Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 2),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/CandidateLogin'),
          child: Text(l10n.navCandidate),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/job-offer'),
          child: Text(l10n.navOffers),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => context.go('/CompanyLogin'),
          child: Text(l10n.navCompany),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
