import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';

class ProfileFormStateView extends StatelessWidget {
  const ProfileFormStateView({
    super.key,
    required this.viewStatus,
    required this.errorMessage,
    required this.onRetry,
    required this.readyChild,
  });

  final ProfileFormViewStatus viewStatus;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Widget readyChild;

  @override
  Widget build(BuildContext context) {
    switch (viewStatus) {
      case ProfileFormViewStatus.initial:
      case ProfileFormViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProfileFormViewStatus.error:
        return StateMessage(
          title: 'No pudimos cargar tu perfil',
          message: errorMessage ?? 'Intenta nuevamente en unos segundos.',
          actionLabel: 'Reintentar',
          onAction: onRetry,
        );
      case ProfileFormViewStatus.empty:
        return const StateMessage(
          title: 'Inicia sesión para ver tu perfil',
          message: 'Necesitas una cuenta activa para editar tu información.',
        );
      case ProfileFormViewStatus.ready:
        return readyChild;
    }
  }
}
