import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final navActionStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface,
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      title: Text(
        'OPTIJOB',
        style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 2),
      ),
      actions: [
        TextButton(
          style: navActionStyle,
          onPressed: () => context.go('/CandidateLogin'),
          child: Text(l10n.navCandidate),
        ),
        TextButton(
          style: navActionStyle,
          onPressed: () => context.go('/job-offer'),
          child: Text(l10n.navOffers),
        ),
        TextButton(
          style: navActionStyle,
          onPressed: () => context.go('/CompanyLogin'),
          child: Text(l10n.navCompany),
        ),
        const SizedBox(width: 8),
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            final isDark = themeState.themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
