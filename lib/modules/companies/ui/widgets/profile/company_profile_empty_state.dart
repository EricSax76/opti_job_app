import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';

class CompanyProfileEmptyState extends StatelessWidget {
  const CompanyProfileEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const StateMessage(
      title: 'Acceso requerido',
      message: 'Inicia sesión para ver tu perfil.',
    );
  }
}
