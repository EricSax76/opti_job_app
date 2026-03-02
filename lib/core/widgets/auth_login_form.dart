import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/auth_form_card.dart';

class AuthLoginForm extends StatefulWidget {
  const AuthLoginForm({
    super.key,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.emailIcon,
    this.emailValidator,
    required this.isLoading,
    required this.onSubmit,
    required this.onRegister,
  });

  final String tagline;
  final String title;
  final String subtitle;
  final IconData emailIcon;
  final String? Function(String?)? emailValidator;
  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onRegister;

  @override
  State<AuthLoginForm> createState() => _AuthLoginFormState();
}

class _AuthLoginFormState extends State<AuthLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormCard(
      tagline: widget.tagline,
      title: widget.title,
      subtitle: widget.subtitle,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(widget.emailIcon),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: widget.emailValidator ??
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    return null;
                  },
            ),
            const SizedBox(height: uiSpacing16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
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
