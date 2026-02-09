import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/features/cover_letter/view/cover_letter_screen.dart';
import 'package:opti_job_app/features/video_curriculum/view/video_curriculum_screen.dart';
import 'package:opti_job_app/modules/curriculum/ui/pages/curriculum_screen.dart';

typedef CandidateDashboardPageBuilder = Widget Function();

final Map<int, CandidateDashboardPageBuilder> _candidateDashboardPageBuilders =
    <int, CandidateDashboardPageBuilder>{
      0: () => const DashboardView(),
      1: () => const MyApplicationsView(),
      2: () => const InterviewsView(),
      3: () => const CurriculumScreen(),
      4: () => const CoverLetterScreen(),
      5: () => const VideoCurriculumScreen(),
    };

Widget candidateDashboardPageForIndex(int index) {
  final builder =
      _candidateDashboardPageBuilders[index] ??
      _candidateDashboardPageBuilders[0]!;
  return builder();
}
