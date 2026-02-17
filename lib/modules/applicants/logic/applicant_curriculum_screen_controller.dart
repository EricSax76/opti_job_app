import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/match_result_dialog.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class ApplicantCurriculumScreenController {
  const ApplicantCurriculumScreenController._();

  static ApplicantCurriculumCubit createCubit(BuildContext context) {
    return ApplicantCurriculumCubit(
      profileRepository: context.read<ProfileRepository>(),
      curriculumRepository: context.read<CurriculumRepository>(),
      jobOfferRepository: context.read<JobOfferRepository>(),
      aiRepository: context.read<AiRepository>(),
    );
  }

  static Future<void> loadInitialData({
    required ApplicantCurriculumCubit cubit,
    required String candidateUid,
    required String offerId,
  }) {
    return cubit.loadData(candidateUid: candidateUid, offerId: offerId);
  }

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
