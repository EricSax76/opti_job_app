import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/containers/candidate_profile_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.cubit});

  final ProfileCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = isDark ? uiDarkBackground : uiBackground;
    final ink = isDark ? uiDarkInk : uiInk;
    final border = isDark ? uiDarkBorder : uiBorder;
    final appBarBg = isDark ? uiDarkBackground : Colors.white;

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('Perfil'),
          centerTitle: true,
          backgroundColor: appBarBg,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: Border(bottom: BorderSide(color: border, width: 1)),
        ),
        body: const CandidateProfileContainer(),
      ),
    );
  }
}
