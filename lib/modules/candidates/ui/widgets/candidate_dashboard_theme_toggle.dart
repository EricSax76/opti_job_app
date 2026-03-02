import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';

class CandidateDashboardThemeToggle extends StatelessWidget {
  const CandidateDashboardThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 140) {
              return IconButton(
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Cambiar tema',
              );
            }
            final showLabel = constraints.maxWidth >= 210;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tema oscuro',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
