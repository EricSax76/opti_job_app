import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/logic/profile_form_logic.dart';

class ProfileFormController {
  const ProfileFormController._();

  static void submit({
    required GlobalKey<FormState> formKey,
    required ProfileFormCubit formCubit,
    required ProfileFormState state,
  }) {
    if (formKey.currentState?.validate() != true) {
      formCubit.notifyValidationFailed();
      return;
    }
    if (!ProfileFormLogic.canSubmit(state)) return;
    formCubit.submit();
  }
}
