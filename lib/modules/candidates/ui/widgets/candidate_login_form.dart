import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/auth_login_form.dart';

class CandidateLoginForm extends StatelessWidget {
  const CandidateLoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onRegister,
    required this.onEudiWallet,
  });

  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onEudiWallet;

  @override
  Widget build(BuildContext context) {
    return AuthLoginForm(
      tagline: 'CANDIDATOS',
      title: 'Inicia sesión',
      subtitle: 'Accede a oportunidades personalizadas y procesos más rápidos.',
      emailIcon: Icons.email_outlined,
      isLoading: isLoading,
      onSubmit: onSubmit,
      onRegister: onRegister,
      secondaryActionLabel: 'Entrar con EUDI Wallet',
      secondaryActionIcon: Icons.badge_outlined,
      onSecondaryAction: onEudiWallet,
    );
  }
}
