import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/providers/router_provider.dart';
import 'package:infojobs_flutter_app/theme/app_theme.dart';

class InfoJobsApp extends ConsumerWidget {
  const InfoJobsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'InfoJobs Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
