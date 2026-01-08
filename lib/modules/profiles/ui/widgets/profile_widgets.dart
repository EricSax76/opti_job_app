import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_form_content.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_state_message.dart';

class CandidateProfileView extends StatelessWidget {
  const CandidateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileFormCubit(profileCubit: context.read<ProfileCubit>()),
      child: const _CandidateProfileContent(),
    );
  }
}

class _CandidateProfileContent extends StatelessWidget {
  const _CandidateProfileContent();

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<ProfileFormCubit>();

    return BlocConsumer<ProfileFormCubit, ProfileFormState>(
      listener: (context, state) {
        if (state.notice != null && state.noticeMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
          context.read<ProfileFormCubit>().clearNotice();
        }
      },
      builder: (context, state) {
        if (state.viewStatus == ProfileFormViewStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.viewStatus == ProfileFormViewStatus.error) {
          return ProfileStateMessage(
            title: 'No pudimos cargar tu perfil',
            message:
                state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
            actionLabel: 'Reintentar',
            onAction: formCubit.refresh,
          );
        }

        if (state.viewStatus == ProfileFormViewStatus.empty) {
          return const ProfileStateMessage(
            title: 'Inicia sesión para ver tu perfil',
            message: 'Necesitas una cuenta activa para editar tu información.',
          );
        }

        return const ProfileFormContent();
      },
    );
  }
}
