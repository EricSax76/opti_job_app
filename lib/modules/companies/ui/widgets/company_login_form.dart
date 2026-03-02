import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/auth_login_form.dart';

class CompanyLoginForm extends StatelessWidget {
  const CompanyLoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onRegister,
  });

  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onRegister;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    return AuthLoginForm(
      tagline: 'EMPRESAS',
      title: 'Inicia sesión',
      subtitle: 'Gestiona tus procesos de selección en un solo lugar.',
      emailIcon: Icons.business_outlined,
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
      onRegister: onRegister,
    );
  }
}
