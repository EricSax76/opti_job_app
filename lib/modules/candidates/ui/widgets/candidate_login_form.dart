import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/auth_form_card.dart';

class CandidateLoginForm extends StatefulWidget {
  const CandidateLoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onRegister,
  });

  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onRegister;

  @override
  State<CandidateLoginForm> createState() => _CandidateLoginFormState();
}

class _CandidateLoginFormState extends State<CandidateLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormCard(
      tagline: 'CANDIDATOS',
      title: 'Inicia sesión',
      subtitle: 'Accede a oportunidades personalizadas y procesos más rápidos.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El correo es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing24),
            FilledButton(
              onPressed: widget.isLoading ? null : _submit,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(uiWhite),
                      ),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: uiSpacing12),
            TextButton(
              onPressed: widget.onRegister,
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }
}

