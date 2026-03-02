import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/auth_register_form.dart';

class CandidateRegisterForm extends StatelessWidget {
  const CandidateRegisterForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
  });

  final bool isLoading;
  final void Function(String name, String email, String password) onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return AuthRegisterForm(
      tagline: 'CANDIDATOS',
      title: 'Crea tu cuenta',
      subtitle: 'Completa tus datos para recibir recomendaciones a tu medida.',
      nameLabel: 'Nombre completo',
      nameIcon: Icons.person_outline,
      emailIcon: Icons.email_outlined,
      isLoading: isLoading,
      onSubmit: onSubmit,
      onLogin: onLogin,
    );
  }
}
