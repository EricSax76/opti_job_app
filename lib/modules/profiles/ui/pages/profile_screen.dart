import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_widgets.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = isDark ? uiDarkBackground : uiBackground;
    final ink = isDark ? uiDarkInk : uiInk;
    final border = isDark ? uiDarkBorder : uiBorder;
    final appBarBg = isDark ? uiDarkBackground : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: appBarBg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),
      body: const CandidateProfileView(),
    );
  }
}
