import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/match_result_dialog.dart';

class ApplicantCurriculumScreenController {
  const ApplicantCurriculumScreenController._();

  static bool shouldListen(
    ApplicantCurriculumState previous,
    ApplicantCurriculumState current,
  ) {
    return previous.infoMessage != current.infoMessage ||
        previous.matchResult != current.matchResult;
  }

  static Future<void> handleSideEffects(
    BuildContext context,
    ApplicantCurriculumState state,
  ) async {
    final infoMessage = state.infoMessage;
    if (infoMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(infoMessage)));
    }

    final matchResult = state.matchResult;
    if (matchResult == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => MatchResultDialog(result: matchResult),
    );
  }
}
