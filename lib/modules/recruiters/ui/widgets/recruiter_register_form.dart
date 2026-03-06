import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/auth_register_form.dart';

class RecruiterRegisterForm extends StatelessWidget {
  const RecruiterRegisterForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
  });

  final bool isLoading;
  final void Function(String name, String email, String password) onSubmit;
  final VoidCallback onLogin;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    return AuthRegisterForm(
      tagline: 'RECRUITERS',
      title: 'Crear cuenta recruiter',
      subtitle:
          'Regístrate como recruiter autónomo. Podrás vincularte a una empresa mediante invitación cuando la recibas.',
      nameLabel: 'Nombre completo',
      nameIcon: Icons.groups_outlined,
      emailIcon: Icons.email_outlined,
      emailValidator: (value) {
        final normalizedValue = value?.trim() ?? '';
        if (normalizedValue.isEmpty) {
          return 'El correo es obligatorio';
        }
        if (!_emailPattern.hasMatch(normalizedValue)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
      isLoading: isLoading,
      onSubmit: onSubmit,
      onLogin: onLogin,
    );
  }
}
