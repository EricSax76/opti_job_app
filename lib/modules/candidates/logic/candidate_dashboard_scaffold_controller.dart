import 'package:flutter/material.dart';

class CandidateDashboardScaffoldController {
  const CandidateDashboardScaffoldController._();

  static void showNewInterviewMessage({
    required BuildContext context,
    required VoidCallback onOpenInterviews,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tienes nuevos mensajes de entrevista'),
        action: SnackBarAction(label: 'Ver', onPressed: onOpenInterviews),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
