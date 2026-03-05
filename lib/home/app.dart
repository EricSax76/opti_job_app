import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

import 'package:opti_job_app/core/theme/app_theme.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';

class InfoJobsApp extends StatelessWidget {
  const InfoJobsApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final focusModeEnabled = themeState.focusModeEnabled;
        final lightTheme = focusModeEnabled
            ? AppTheme.light.copyWith(visualDensity: VisualDensity.compact)
            : AppTheme.light;
        final darkTheme = focusModeEnabled
            ? AppTheme.dark.copyWith(visualDensity: VisualDensity.compact)
            : AppTheme.dark;

        return MaterialApp.router(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'Opti Job',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          themeAnimationDuration: Duration.zero,
          themeAnimationCurve: Curves.linear,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final media = MediaQuery.maybeOf(context);
            if (media == null) return child;
            return MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    focusModeEnabled || media.disableAnimations,
              ),
              child: child,
            );
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    );
  }
}
