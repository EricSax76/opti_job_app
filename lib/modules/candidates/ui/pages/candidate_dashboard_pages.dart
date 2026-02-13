import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/features/cover_letter/view/cover_letter_screen.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_curriculum_screen.dart';
import 'package:opti_job_app/modules/curriculum/ui/pages/curriculum_screen.dart';

Widget candidateDashboardPageForIndex(int index) {
  return switch (index) {
    1 => const MyApplicationsView(),
    2 => const InterviewsView(),
    3 => const CurriculumScreen(),
    4 => const CoverLetterScreen(),
    5 => const VideoCurriculumScreen(),
    _ => const DashboardView(),
  };
}
