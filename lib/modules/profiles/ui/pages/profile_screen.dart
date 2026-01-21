import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_widgets.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = uiBackground;
    const ink = uiInk;
    const border = uiBorder;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),
      body: const CandidateProfileView(),
    );
  }
}
