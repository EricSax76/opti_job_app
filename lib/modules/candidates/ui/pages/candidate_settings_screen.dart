import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';

class CandidateSettingsScreen extends StatefulWidget {
  const CandidateSettingsScreen({super.key});

  @override
  State<CandidateSettingsScreen> createState() =>
      _CandidateSettingsScreenState();
}

class _CandidateSettingsScreenState extends State<CandidateSettingsScreen> {
  bool _isImportingCredential = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = colorScheme.surface;
    final border = colorScheme.outlineVariant;
    final appBarBg = colorScheme.surface;
    ThemeCubit? themeCubit;
    try {
      themeCubit = context.read<ThemeCubit>();
    } catch (_) {
      themeCubit = null;
    }
    final focusModeEnabled =
        themeCubit?.state.focusModeEnabled ?? false;
    final candidateUid = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.uid,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
        backgroundColor: appBarBg,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          uiSpacing16,
          uiSpacing16,
          uiSpacing16,
          uiSpacing24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SettingsPlaceholderMessage(),
            const SizedBox(height: uiSpacing16),
            if (themeCubit != null) ...[
              _FocusModeSection(
                enabled: focusModeEnabled,
                onChanged: themeCubit.setFocusModeEnabled,
              ),
              const SizedBox(height: uiSpacing16),
            ],
            _EudiWalletSection(
              candidateUid: candidateUid,
              isImportingCredential: _isImportingCredential,
              onImportCredential: () => _importCredential(context),
            ),
            const SizedBox(height: uiSpacing16),
            const _SettingsSection(
              title: 'Datos de acceso',
              items: ['Cambiar email', 'Cambiar contraseña'],
            ),
            const SizedBox(height: uiSpacing16),
            const _SettingsSection(
              title: 'Notificaciones y consejos',
              items: [
                'Alertas de empleo por email',
                'Configura tus comunicaciones',
              ],
            ),
            const SizedBox(height: uiSpacing16),
            const _SettingsSection(
              title: 'Privacidad',
              items: ['Qué ven las empresas', 'Bloquear empresas'],
            ),
            const SizedBox(height: uiSpacing16),
            const _SettingsStandaloneItem(
              title: 'Promociones de nuestros productos',
            ),
            const SizedBox(height: uiSpacing12),
            const _SettingsStandaloneItem(title: 'Publicidad programática'),
            const SizedBox(height: uiSpacing16),
            const _SettingsSection(
              title: 'Cómo gestionamos tus datos',
              items: ['Descarga una copia de tus datos.'],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCredential(BuildContext context) async {
    if (_isImportingCredential) return;
    final repository = context.read<AuthRepository>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() => _isImportingCredential = true);
    try {
      await repository.importEudiCredentialFromNativeWallet();
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Credencial verificada importada correctamente.'),
          ),
        );
    } catch (error) {
      final message = repository.mapException(error).message;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isImportingCredential = false);
      }
    }
  }
}

class _EudiWalletSection extends StatelessWidget {
  const _EudiWalletSection({
    required this.candidateUid,
    required this.isImportingCredential,
    required this.onImportCredential,
  });

  final String? candidateUid;
  final bool isImportingCredential;
  final VoidCallback onImportCredential;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final border = colorScheme.outlineVariant;
    final normalizedUid = candidateUid?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(uiSpacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Credenciales verificadas (EUDI Wallet)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: uiSpacing8),
            Text(
              'Importa títulos/certificaciones verificadas y comparte pruebas selectivas (ZKP) sin exponer el documento completo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: uiSpacing12),
            if (normalizedUid.isEmpty)
              const Text('Inicia sesión para ver tus credenciales verificadas.')
            else
              _CredentialList(candidateUid: normalizedUid),
            const SizedBox(height: uiSpacing12),
            Semantics(
              button: true,
              label: 'Importar credencial EUDI',
              hint:
                  'Abre el flujo nativo de wallet para importar credenciales verificadas.',
              child: OutlinedButton.icon(
                onPressed: isImportingCredential ? null : onImportCredential,
                icon: isImportingCredential
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_link_outlined),
                label: const Text('Importar credencial EUDI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialList extends StatefulWidget {
  const _CredentialList({required this.candidateUid});

  final String candidateUid;

  @override
  State<_CredentialList> createState() => _CredentialListState();
}

class _CredentialListState extends State<_CredentialList> {
  final Set<String> _creatingProofForCredentials = <String>{};
  final Set<String> _revokingProofIds = <String>{};

  Future<void> _createSelectiveProof(String credentialId) async {
    if (_creatingProofForCredentials.contains(credentialId)) return;
    final repository = context.read<AuthRepository>();
    final params = await _showCreateProofDialog();
    if (!mounted || params == null) return;

    setState(() => _creatingProofForCredentials.add(credentialId));
    try {
      final result = await repository.createSelectiveDisclosureProof(
        input: SelectiveDisclosureProofInput(
          credentialId: credentialId,
          claimKey: params.claimKey,
          statement: params.statement,
          applicationId: params.applicationId,
          audienceCompanyUid: params.audienceCompanyUid,
          expiresInMinutes: params.expiresInMinutes,
        ),
      );

      if (!mounted) return;
      await _showProofCreatedDialog(result);
    } catch (error) {
      if (!mounted) return;
      final message = repository.mapException(error).message;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _creatingProofForCredentials.remove(credentialId));
      }
    }
  }

  Future<_SelectiveDisclosureDialogResult?> _showCreateProofDialog() {
    final applicationController = TextEditingController();
    final companyController = TextEditingController();
    final claimKeyController = TextEditingController(text: 'type');
    final statementController = TextEditingController(
      text:
          'Prueba de posesión emitida con divulgación selectiva para proceso de selección.',
    );
    final expiresController = TextEditingController(text: '60');
    final formKey = GlobalKey<FormState>();

    return showDialog<_SelectiveDisclosureDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generar prueba selectiva'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: applicationController,
                    decoration: const InputDecoration(
                      labelText: 'ID de candidatura (recomendado)',
                    ),
                  ),
                  const SizedBox(height: uiSpacing8),
                  TextFormField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText:
                          'UID empresa destino (si no indicas candidatura)',
                    ),
                  ),
                  const SizedBox(height: uiSpacing8),
                  TextFormField(
                    controller: claimKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Claim a demostrar',
                      helperText: 'Ejemplo: type, title, issuer',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Indica el claim a demostrar.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: uiSpacing8),
                  TextFormField(
                    controller: statementController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje visible para la empresa',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: uiSpacing8),
                  TextFormField(
                    controller: expiresController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expiración (minutos)',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null || parsed < 5 || parsed > 1440) {
                        return 'Introduce un valor entre 5 y 1440.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final appId = applicationController.text.trim();
                final companyUid = companyController.text.trim();
                if (!formKey.currentState!.validate()) return;
                if (appId.isEmpty && companyUid.isEmpty) {
                  ScaffoldMessenger.maybeOf(dialogContext)
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Indica candidatura o empresa destino para generar la prueba.',
                        ),
                      ),
                    );
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _SelectiveDisclosureDialogResult(
                    applicationId: appId,
                    audienceCompanyUid: companyUid,
                    claimKey: claimKeyController.text.trim(),
                    statement: statementController.text.trim(),
                    expiresInMinutes:
                        int.tryParse(expiresController.text.trim()) ?? 60,
                  ),
                );
              },
              child: const Text('Generar prueba'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProofCreatedDialog(SelectiveDisclosureProofResult result) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Prueba generada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CopyFieldTile(
                label: 'Proof ID',
                value: result.proofId,
                onCopy: () => _copyValue(result.proofId),
              ),
              const SizedBox(height: uiSpacing8),
              _CopyFieldTile(
                label: 'Proof Token',
                value: result.proofToken,
                onCopy: () => _copyValue(result.proofToken),
              ),
              const SizedBox(height: uiSpacing8),
              Text(
                'Comparte ambos valores por un canal seguro. El token no se vuelve a mostrar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyValue(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copiado al portapapeles.')));
  }

  Future<void> _revokeProof(String proofId) async {
    if (_revokingProofIds.contains(proofId)) return;
    final repository = context.read<AuthRepository>();
    setState(() => _revokingProofIds.add(proofId));
    try {
      await repository.revokeSelectiveDisclosureProof(proofId: proofId);
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Prueba selectiva revocada.')),
        );
    } catch (error) {
      if (!mounted) return;
      final message = repository.mapException(error).message;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _revokingProofIds.remove(proofId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('candidates')
        .doc(widget.candidateUid)
        .collection('verifiedCredentials')
        .orderBy('updatedAt', descending: true)
        .limit(10)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: uiSpacing8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'No se pudieron cargar las credenciales verificadas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (docs.isEmpty)
              Text(
                'Aún no has importado credenciales verificadas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                final title =
                    (data['title'] as String?)?.trim() ?? 'Credencial';
                final issuer = (data['issuer'] as String?)?.trim() ?? 'Emisor';
                final type = (data['type'] as String?)?.trim() ?? 'credential';
                final issuedAt = (data['issuedAt'] as String?)?.trim();
                final subtitleParts = <String>[
                  issuer,
                  'Tipo: $type',
                  if (issuedAt != null && issuedAt.isNotEmpty)
                    'Emitida: ${issuedAt.split('T').first}',
                ];
                final isCreating = _creatingProofForCredentials.contains(
                  doc.id,
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    subtitleParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: isCreating
                        ? null
                        : () => _createSelectiveProof(doc.id),
                    icon: isCreating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: const Text('Crear ZKP'),
                  ),
                );
              }),
            const SizedBox(height: uiSpacing8),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: uiSpacing8),
            Text(
              'Pruebas selectivas generadas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: uiSpacing8),
            _SelectiveProofList(
              candidateUid: widget.candidateUid,
              revokingProofIds: _revokingProofIds,
              onRevoke: _revokeProof,
              onCopy: _copyValue,
            ),
          ],
        );
      },
    );
  }
}

class _SelectiveDisclosureDialogResult {
  const _SelectiveDisclosureDialogResult({
    required this.applicationId,
    required this.audienceCompanyUid,
    required this.claimKey,
    required this.statement,
    required this.expiresInMinutes,
  });

  final String applicationId;
  final String audienceCompanyUid;
  final String claimKey;
  final String statement;
  final int expiresInMinutes;
}

class _CopyFieldTile extends StatelessWidget {
  const _CopyFieldTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copiar',
          onPressed: onCopy,
          icon: const Icon(Icons.copy_all_outlined),
        ),
      ],
    );
  }
}

class _SelectiveProofList extends StatelessWidget {
  const _SelectiveProofList({
    required this.candidateUid,
    required this.revokingProofIds,
    required this.onRevoke,
    required this.onCopy,
  });

  final String candidateUid;
  final Set<String> revokingProofIds;
  final ValueChanged<String> onRevoke;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('credentialProofShares')
        .where('candidateUid', isEqualTo: candidateUid)
        .limit(20)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text(
            'No se pudieron cargar las pruebas selectivas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }

        final docs = [...(snapshot.data?.docs ?? const [])]
          ..sort((a, b) {
            final aDate = _parseTimestamp(a.data()['createdAt']);
            final bDate = _parseTimestamp(b.data()['createdAt']);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
        if (docs.isEmpty) {
          return Text(
            'Aún no has generado pruebas selectivas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          children: docs
              .map((doc) {
                final data = doc.data();
                final proofId = (data['proofId'] as String?)?.trim() ?? doc.id;
                final statement =
                    (data['statement'] as String?)?.trim().isNotEmpty == true
                    ? (data['statement'] as String).trim()
                    : 'Prueba selectiva';
                final status = (data['status'] as String?)?.trim() ?? 'active';
                final expiresAt = _parseTimestamp(data['expiresAt']);
                final expiresLabel = expiresAt == null
                    ? 'Sin expiración'
                    : 'Expira: ${expiresAt.toLocal()}'.split('.').first;
                final isRevoking = revokingProofIds.contains(proofId);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    status == 'active'
                        ? Icons.verified_user_outlined
                        : Icons.block_outlined,
                  ),
                  title: Text(
                    statement,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'ID: $proofId • Estado: $status • $expiresLabel',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Copiar proofId',
                        onPressed: () => onCopy(proofId),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                      if (status == 'active')
                        IconButton(
                          tooltip: 'Revocar prueba',
                          onPressed: isRevoking
                              ? null
                              : () => onRevoke(proofId),
                          icon: isRevoking
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cancel_outlined),
                        ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

DateTime? _parseTimestamp(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class _SettingsPlaceholderMessage extends StatelessWidget {
  const _SettingsPlaceholderMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final border = colorScheme.outlineVariant;
    return Container(
      padding: const EdgeInsets.all(uiSpacing16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: Text(
        'Estamos preparando cada apartado. En otro momento desarrollaremos cada sección.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _FocusModeSection extends StatelessWidget {
  const _FocusModeSection({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final border = colorScheme.outlineVariant;
    final cardColor = theme.cardTheme.color ?? colorScheme.surface;

    return Semantics(
      container: true,
      label: 'Modo enfoque para candidatos',
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(uiTileRadius),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: enabled,
              onChanged: onChanged,
              title: const Text('Modo enfoque'),
              subtitle: const Text(
                'Reduce estímulos visuales y prioriza acciones esenciales.',
              ),
              secondary: const Icon(Icons.center_focus_strong_outlined),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                uiSpacing16,
                uiSpacing12,
                uiSpacing16,
                uiSpacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FocusModeBullet(
                    icon: Icons.visibility_off_outlined,
                    text: 'Oculta paneles no esenciales.',
                  ),
                  SizedBox(height: uiSpacing8),
                  _FocusModeBullet(
                    icon: Icons.motion_photos_paused_outlined,
                    text: 'Reduce o pausa animaciones no necesarias.',
                  ),
                  SizedBox(height: uiSpacing8),
                  _FocusModeBullet(
                    icon: Icons.density_small_outlined,
                    text: 'Simplifica la densidad visual de la interfaz.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusModeBullet extends StatelessWidget {
  const _FocusModeBullet({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: uiSpacing8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final border = colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              uiSpacing16,
              uiSpacing16,
              uiSpacing16,
              uiSpacing8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: uiSpacing16,
              ),
              title: Text(items[i]),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsStandaloneItem extends StatelessWidget {
  const _SettingsStandaloneItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    final border = colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
