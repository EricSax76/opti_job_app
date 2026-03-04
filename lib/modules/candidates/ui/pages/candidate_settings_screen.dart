import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/auth/ui/widgets/eudi_wallet_dialogs.dart';
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
    final credential = await showEudiCredentialImportDialog(context);
    if (credential == null || !context.mounted) return;

    setState(() => _isImportingCredential = true);
    try {
      await repository.importEudiCredential(credential: credential);
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
              'Importa y gestiona títulos o certificaciones firmadas digitalmente.',
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
            OutlinedButton.icon(
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
          ],
        ),
      ),
    );
  }
}

class _CredentialList extends StatelessWidget {
  const _CredentialList({required this.candidateUid});

  final String candidateUid;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('candidates')
        .doc(candidateUid)
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
        if (docs.isEmpty) {
          return Text(
            'Aún no has importado credenciales verificadas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          children: docs
              .map((doc) {
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
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
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
