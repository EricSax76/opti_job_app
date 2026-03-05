import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/auth_form_card.dart';

class AuthRegisterForm extends StatefulWidget {
  const AuthRegisterForm({
    super.key,
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.nameLabel,
    required this.nameIcon,
    required this.emailIcon,
    this.emailValidator,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  final String tagline;
  final String title;
  final String subtitle;
  final String nameLabel;
  final IconData nameIcon;
  final IconData emailIcon;
  final String? Function(String?)? emailValidator;
  final bool isLoading;
  final void Function(String name, String email, String password) onSubmit;
  final VoidCallback onLogin;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  @override
  State<AuthRegisterForm> createState() => _AuthRegisterFormState();
}

class _AuthRegisterFormState extends State<AuthRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'register_name');
  final _emailFocusNode = FocusNode(debugLabel: 'register_email');
  final _passwordFocusNode = FocusNode(debugLabel: 'register_password');
  final _confirmPasswordFocusNode = FocusNode(debugLabel: 'register_confirm');
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _acceptedPrivacyPolicy = false;
  var _acceptedCookiesPolicy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: widget.nameLabel,
                    prefixIcon: Icon(widget.nameIcon),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocusNode);
                  },
                ),
                const SizedBox(height: uiSpacing16),
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
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
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(
                      context,
                    ).requestFocus(_confirmPasswordFocusNode);
                  },
                ),
                const SizedBox(height: uiSpacing16),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Repetir contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Semantics(
                      button: true,
                      label: _obscureConfirm
                          ? 'Mostrar confirmación de contraseña'
                          : 'Ocultar confirmación de contraseña',
                      child: IconButton(
                        tooltip: _obscureConfirm
                            ? 'Mostrar confirmación de contraseña'
                            : 'Ocultar confirmación de contraseña',
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: uiSpacing16),
                _LegalNoticesSection(
                  acceptedPrivacyPolicy: _acceptedPrivacyPolicy,
                  acceptedCookiesPolicy: _acceptedCookiesPolicy,
                  onPrivacyPolicyChanged: (value) =>
                      setState(() => _acceptedPrivacyPolicy = value ?? false),
                  onCookiesPolicyChanged: (value) =>
                      setState(() => _acceptedCookiesPolicy = value ?? false),
                  onOpenPrivacyPolicy: _showPrivacyPolicyDialog,
                  onOpenCookiesPolicy: _showCookiesPolicyDialog,
                ),
                const SizedBox(height: uiSpacing24),
                Semantics(
                  button: true,
                  enabled: !widget.isLoading,
                  label: widget.isLoading
                      ? 'Creando cuenta'
                      : 'Crear cuenta con correo y contraseña',
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
                        : const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: uiSpacing12),
                Semantics(
                  button: true,
                  label: 'Ir a inicio de sesión',
                  child: TextButton(
                    onPressed: widget.onLogin,
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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
    if (!_acceptedPrivacyPolicy || !_acceptedCookiesPolicy) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Debes aceptar la Política de Privacidad y la Política de Cookies para crear la cuenta.',
            ),
          ),
        );
      return;
    }

    widget.onSubmit(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _showPrivacyPolicyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Política de Privacidad'),
          content: const SingleChildScrollView(
            child: Text(
              'Tratamos tus datos para gestionar tu cuenta y procesos de selección. '
              'Podrás ejercer tus derechos de acceso, rectificación, supresión, '
              'portabilidad, limitación y oposición desde el Portal de Privacidad.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCookiesPolicyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Política de Cookies'),
          content: const SingleChildScrollView(
            child: Text(
              'Usamos cookies técnicas para funcionamiento y seguridad. '
              'También podemos usar cookies de analítica para mejorar el servicio, '
              'según la configuración de consentimiento aplicable en tu entorno.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _LegalNoticesSection extends StatelessWidget {
  const _LegalNoticesSection({
    required this.acceptedPrivacyPolicy,
    required this.acceptedCookiesPolicy,
    required this.onPrivacyPolicyChanged,
    required this.onCookiesPolicyChanged,
    required this.onOpenPrivacyPolicy,
    required this.onOpenCookiesPolicy,
  });

  final bool acceptedPrivacyPolicy;
  final bool acceptedCookiesPolicy;
  final ValueChanged<bool?> onPrivacyPolicyChanged;
  final ValueChanged<bool?> onCookiesPolicyChanged;
  final VoidCallback onOpenPrivacyPolicy;
  final VoidCallback onOpenCookiesPolicy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(uiSpacing12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avisos legales',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: uiSpacing8),
          Wrap(
            spacing: uiSpacing8,
            runSpacing: uiSpacing8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenPrivacyPolicy,
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Ver privacidad'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenCookiesPolicy,
                icon: const Icon(Icons.cookie_outlined),
                label: const Text('Ver cookies'),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing8),
          CheckboxListTile.adaptive(
            value: acceptedPrivacyPolicy,
            onChanged: onPrivacyPolicyChanged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('He leído y acepto la Política de Privacidad.'),
          ),
          CheckboxListTile.adaptive(
            value: acceptedCookiesPolicy,
            onChanged: onCookiesPolicyChanged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('He leído y acepto la Política de Cookies.'),
          ),
        ],
      ),
    );
  }
}
