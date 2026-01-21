import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: uiBackground,
      child: Text(
        l10n.footerCopyright(currentYear),
        textAlign: TextAlign.center,
        style: const TextStyle(color: uiMuted, fontSize: 13),
      ),
    );
  }
}
