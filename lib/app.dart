import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/theme/app_theme.dart';

class InfoJobsApp extends StatelessWidget {
  const InfoJobsApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InfoJobs Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
