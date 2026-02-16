import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';

class CurriculumFormStateView extends StatelessWidget {
  const CurriculumFormStateView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.readyChild,
  });

  final CurriculumFormState state;
  final VoidCallback onRetry;
  final Widget readyChild;

  @override
  Widget build(BuildContext context) {
    if (state.viewStatus == CurriculumFormViewStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.viewStatus == CurriculumFormViewStatus.error) {
      return StateMessage(
        title: 'No pudimos cargar tu curriculum',
        message: state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
        actionLabel: 'Reintentar',
        onAction: onRetry,
      );
    }

    if (state.viewStatus == CurriculumFormViewStatus.empty) {
      return const StateMessage(
        title: 'Inicia sesión para ver tu curriculum',
        message: 'Necesitas una cuenta activa para editar tu CV.',
      );
    }

    return readyChild;
  }
}
