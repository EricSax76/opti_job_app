import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/logic/profile_form_logic.dart';

class CandidateProfileController {
  const CandidateProfileController._();

  static void handleNotice(BuildContext context, ProfileFormState state) {
    final message = ProfileFormLogic.resolveNoticeMessage(state);
    if (message == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.read<ProfileFormCubit>().clearNotice();
  }
}
