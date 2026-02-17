import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/generic_applications_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/features/cover_letter/view/containers/cover_letter_container.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_curriculum_screen.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/pages/curriculum_screen.dart';

Widget candidateDashboardPageForIndex(
  int index, {
  required CurriculumFormCubit curriculumFormCubit,
}) {
  return switch (index) {
    1 => const GenericApplicationsView(
      heroTagPrefix: 'my-applications',
      emptyTitle: 'Sin postulaciones',
      emptyMessage: 'Aún no te has postulado a ninguna oferta.',
    ),
    2 => const InterviewsView(),
    3 => CurriculumScreen(cubit: curriculumFormCubit),
    4 => const CoverLetterContainer(),
    5 => const VideoCurriculumScreen(),
    _ => const DashboardView(),
  };
}
