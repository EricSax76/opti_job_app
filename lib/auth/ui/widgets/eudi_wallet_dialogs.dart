import 'package:flutter/material.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';

Future<EudiWalletSignInInput?> showEudiWalletSignInDialog(
  BuildContext context, {
  String? initialName,
  String? initialEmail,
}) {
  return showDialog<EudiWalletSignInInput>(
    context: context,
    builder: (context) => _EudiWalletSignInDialog(
      initialName: initialName,
      initialEmail: initialEmail,
    ),
  );
}

Future<EudiWalletCredentialInput?> showEudiCredentialImportDialog(
  BuildContext context,
) {
  return showDialog<EudiWalletCredentialInput>(
    context: context,
    builder: (context) => const _EudiCredentialDialog(),
  );
}

class _EudiWalletSignInDialog extends StatefulWidget {
  const _EudiWalletSignInDialog({this.initialName, this.initialEmail});

  final String? initialName;
  final String? initialEmail;

  @override
  State<_EudiWalletSignInDialog> createState() =>
      _EudiWalletSignInDialogState();
}

class _EudiWalletSignInDialogState extends State<_EudiWalletSignInDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  final TextEditingController _walletSubjectController = TextEditingController(
    text: 'wallet-${DateTime.now().millisecondsSinceEpoch}',
  );
  final TextEditingController _countryCodeController = TextEditingController(
    text: 'ES',
  );
  String _assuranceLevel = 'substantial';
  bool _importCredential = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _walletSubjectController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acceso con EUDI Wallet'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final normalized = value?.trim() ?? '';
                  if (normalized.isEmpty || !normalized.contains('@')) {
                    return 'Introduce un email válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _walletSubjectController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Subject',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'walletSubject es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _assuranceLevel,
                decoration: const InputDecoration(
                  labelText: 'Nivel de garantía',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'substantial',
                    child: Text('Substantial'),
                  ),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() => _assuranceLevel = value ?? 'substantial');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryCodeController,
                decoration: const InputDecoration(
                  labelText: 'País emisor (ISO2)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Importar una credencial verificada'),
                value: _importCredential,
                onChanged: (value) {
                  setState(() => _importCredential = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final navigator = Navigator.of(context);
            EudiWalletCredentialInput? credential;
            if (_importCredential) {
              credential = await showEudiCredentialImportDialog(context);
              if (credential == null) return;
            }
            if (!mounted) return;
            navigator.pop(
              EudiWalletSignInInput(
                walletSubject: _walletSubjectController.text.trim(),
                email: _emailController.text.trim().toLowerCase(),
                fullName: _fullNameController.text.trim(),
                countryCode: _countryCodeController.text.trim().toUpperCase(),
                assuranceLevel: _assuranceLevel,
                credential: credential,
              ),
            );
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _EudiCredentialDialog extends StatefulWidget {
  const _EudiCredentialDialog();

  @override
  State<_EudiCredentialDialog> createState() => _EudiCredentialDialogState();
}

class _EudiCredentialDialogState extends State<_EudiCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'degree';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _issuedAtController = TextEditingController();
  final TextEditingController _expiresAtController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _issuerController.dispose();
    _issuedAtController.dispose();
    _expiresAtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Credencial verificada'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'degree', child: Text('Título')),
                  DropdownMenuItem(
                    value: 'certification',
                    child: Text('Certificación'),
                  ),
                  DropdownMenuItem(
                    value: 'experience',
                    child: Text('Experiencia laboral'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'degree'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título/credencial',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Entidad emisora',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuedAtController,
                decoration: const InputDecoration(
                  labelText: 'Fecha emisión (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiresAtController,
                decoration: const InputDecoration(
                  labelText: 'Caducidad opcional (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.event_busy_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              EudiWalletCredentialInput(
                type: _type,
                title: _titleController.text.trim(),
                issuer: _issuerController.text.trim(),
                issuedAt: _tryParseDate(_issuedAtController.text),
                expiresAt: _tryParseDate(_expiresAtController.text),
              ),
            );
          },
          child: const Text('Importar'),
        ),
      ],
    );
  }

  DateTime? _tryParseDate(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}
