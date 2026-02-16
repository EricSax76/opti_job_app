import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/containers/profile_form_container.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_form_state_view.dart';

class CandidateProfileContainer extends StatelessWidget {
  const CandidateProfileContainer({super.key});

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
        if (state.notice == null || state.noticeMessage == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
        formCubit.clearNotice();
      },
      builder: (context, state) {
        return ProfileFormStateView(
          viewStatus: state.viewStatus,
          errorMessage: state.errorMessage,
          onRetry: formCubit.refresh,
          readyChild: const ProfileFormContainer(),
        );
      },
    );
  }
}
