import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/features/cover_letter/view/cover_letter_screen.dart';
import 'package:opti_job_app/features/cover_letter/view/video_curriculum_screen.dart';
import 'package:opti_job_app/modules/curriculum/ui/pages/curriculum_screen.dart';

const candidateDashboardPages = <Widget>[
  DashboardView(),
  MyApplicationsView(),
  InterviewsView(),
  CurriculumScreen(),
  CoverLetterScreen(),
  VideoCurriculumScreen(),
];
