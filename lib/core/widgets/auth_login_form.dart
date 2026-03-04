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
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  final String tagline;
  final String title;
  final String subtitle;
  final IconData emailIcon;
  final String? Function(String?)? emailValidator;
  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onRegister;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  @override
  State<AuthLoginForm> createState() => _AuthLoginFormState();
}

class _AuthLoginFormState extends State<AuthLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode(debugLabel: 'login_email');
  final _passwordFocusNode = FocusNode(debugLabel: 'login_password');
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormCard(
      tagline: widget.tagline,
      title: widget.title,
      subtitle: widget.subtitle,
      child: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'nombre@empresa.com',
                    prefixIcon: Icon(widget.emailIcon),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      widget.emailValidator ??
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'El correo es obligatorio';
                        }
                        return null;
                      },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                ),
                const SizedBox(height: uiSpacing16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Semantics(
                      button: true,
                      label: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      child: IconButton(
                        tooltip: _obscurePassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: uiSpacing24),
                Semantics(
                  button: true,
                  enabled: !widget.isLoading,
                  label: widget.isLoading
                      ? 'Iniciando sesión'
                      : 'Entrar con correo y contraseña',
                  child: FilledButton(
                    onPressed: widget.isLoading ? null : _submit,
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                uiWhite,
                              ),
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: uiSpacing12),
                Semantics(
                  button: true,
                  label: 'Ir a registro',
                  child: TextButton(
                    onPressed: widget.onRegister,
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ),
                if (widget.onSecondaryAction != null &&
                    widget.secondaryActionLabel != null) ...[
                  const SizedBox(height: uiSpacing8),
                  OutlinedButton.icon(
                    onPressed: widget.isLoading
                        ? null
                        : widget.onSecondaryAction,
                    icon: Icon(
                      widget.secondaryActionIcon ??
                          Icons.account_balance_wallet_outlined,
                    ),
                    label: Text(widget.secondaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(_emailController.text.trim(), _passwordController.text);
  }
}
