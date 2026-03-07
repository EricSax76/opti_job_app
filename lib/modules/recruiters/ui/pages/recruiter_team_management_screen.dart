import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';
import 'package:opti_job_app/modules/recruiters/repositories/recruiter_repository.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';

class RecruiterTeamManagementScreen extends StatefulWidget {
  const RecruiterTeamManagementScreen({super.key, required this.recruiterUid});

  final String recruiterUid;

  @override
  State<RecruiterTeamManagementScreen> createState() =>
      _RecruiterTeamManagementScreenState();
}

class _RecruiterTeamManagementScreenState
    extends State<RecruiterTeamManagementScreen> {
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _acceptCodeController = TextEditingController();
  final TextEditingController _acceptNameController = TextEditingController();

  RecruiterRole _inviteRole = RecruiterRole.recruiter;
  bool _isCreatingInvitation = false;
  bool _isAcceptingInvitation = false;
  final Set<String> _updatingRoleUids = <String>{};
  final Set<String> _removingUids = <String>{};

  @override
  void dispose() {
    _inviteEmailController.dispose();
    _acceptCodeController.dispose();
    _acceptNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recruiter = context.watch<RecruiterAuthCubit>().state.recruiter;
    if (recruiter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de equipo')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/recruiter-login'),
            child: const Text('Iniciar sesión'),
          ),
        ),
      );
    }

    final normalizedRouteUid = widget.recruiterUid.trim();
    if (normalizedRouteUid.isNotEmpty && normalizedRouteUid != recruiter.uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go('/recruiter/${recruiter.uid}/team');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_acceptNameController.text.trim().isEmpty) {
      _acceptNameController.text = recruiter.name;
    }

    final rbac = context.read<RbacService>();
    final repository = context.read<RecruiterRepository>();
    final canManageTeam = rbac.canManageTeam(recruiter);
    final canInviteMembers = rbac.canInviteMembers(recruiter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de equipo'),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () =>
                context.go('/recruiter/${recruiter.uid}/dashboard'),
            icon: const Icon(Icons.dashboard_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!recruiter.hasCompanyAssociation) ...[
            _buildAcceptInvitationCard(repository: repository),
            const SizedBox(height: 16),
          ],
          if (recruiter.hasCompanyAssociation) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empresa: ${recruiter.companyId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canManageTeam
                          ? 'Tienes permisos para gestionar el equipo.'
                          : 'No tienes permisos para gestionar miembros.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (canInviteMembers) ...[
            _buildCreateInvitationCard(repository: repository),
            const SizedBox(height: 16),
          ],
          if (canManageTeam && recruiter.hasCompanyAssociation)
            _buildTeamMembersCard(repository: repository, recruiter: recruiter),
          if (!canManageTeam && recruiter.hasCompanyAssociation)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Solicita a un administrador que te otorgue permisos para gestionar invitaciones y roles.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcceptInvitationCard({required RecruiterRepository repository}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unirme a una empresa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Introduce un código de invitación de 6 caracteres para vincular tu cuenta recruiter a una empresa.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _acceptCodeController,
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                hintText: 'AB12CD',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _acceptNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre visible',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isAcceptingInvitation
                  ? null
                  : () => _acceptInvitation(repository),
              icon: _isAcceptingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Aceptar invitación'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateInvitationCard({required RecruiterRepository repository}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear invitación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecruiterRole>(
              initialValue: _inviteRole,
              decoration: const InputDecoration(
                labelText: 'Rol a invitar',
                border: OutlineInputBorder(),
              ),
              items: RecruiterRole.values
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(_roleLabel(role)),
                    ),
                  )
                  .toList(),
              onChanged: _isCreatingInvitation
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _inviteRole = value);
                    },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                hintText: 'usuario@empresa.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isCreatingInvitation
                  ? null
                  : () => _createInvitation(repository),
              icon: _isCreatingInvitation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: const Text('Generar código'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersCard({
    required RecruiterRepository repository,
    required Recruiter recruiter,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Recruiter>>(
          stream: repository.watchCompanyRecruiters(recruiter.companyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final members = snapshot.data ?? const <Recruiter>[];
            if (members.isEmpty) {
              return const Text('No hay miembros activos o invitados.');
            }

            final sorted = [...members]
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Miembros del equipo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...sorted.map(
                  (member) => _MemberTile(
                    member: member,
                    isCurrentUser: member.uid == recruiter.uid,
                    isUpdatingRole: _updatingRoleUids.contains(member.uid),
                    isRemoving: _removingUids.contains(member.uid),
                    roleLabel: _roleLabel(member.role),
                    statusLabel: _statusLabel(member.status),
                    onChangeRole: member.uid == recruiter.uid
                        ? null
                        : () => _showRolePicker(
                            repository: repository,
                            member: member,
                          ),
                    onRemove: member.uid == recruiter.uid
                        ? null
                        : () => _removeRecruiter(
                            repository: repository,
                            uid: member.uid,
                            name: member.name,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createInvitation(RecruiterRepository repository) async {
    setState(() => _isCreatingInvitation = true);
    try {
      final code = await repository.createInvitation(
        role: _inviteRole,
        email: _inviteEmailController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Código generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comparte este código con el nuevo miembro del equipo:',
              ),
              const SizedBox(height: 12),
              SelectableText(
                code,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.of(context).pop();
              },
              child: const Text('Copiar y cerrar'),
            ),
          ],
        ),
      );
      _inviteEmailController.clear();
    } catch (error) {
      _showError(_readableError(error));
    } finally {
      if (mounted) setState(() => _isCreatingInvitation = false);
    }
  }

  Future<void> _acceptInvitation(RecruiterRepository repository) async {
    final code = _acceptCodeController.text.trim().toUpperCase();
    final name = _acceptNameController.text.trim();
    if (code.length != 6) {
      _showError('El código debe tener 6 caracteres.');
      return;
    }
    if (name.isEmpty) {
      _showError('El nombre es obligatorio.');
      return;
    }

    setState(() => _isAcceptingInvitation = true);
    try {
      await repository.acceptInvitation(code: code, name: name);
      if (!mounted) return;
      _acceptCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación aceptada correctamente.')),
      );
      await context.read<RecruiterAuthCubit>().restoreSession();
    } catch (error) {
      _showError(_readableError(error));
    } finally {
      if (mounted) setState(() => _isAcceptingInvitation = false);
    }
  }

  Future<void> _showRolePicker({
    required RecruiterRepository repository,
    required Recruiter member,
  }) async {
    final selected = await showModalBottomSheet<RecruiterRole>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: RecruiterRole.values
              .map(
                (role) => ListTile(
                  title: Text(_roleLabel(role)),
                  trailing: role == member.role
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(role),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected == null || selected == member.role) return;

    setState(() => _updatingRoleUids.add(member.uid));
    try {
      await repository.updateRecruiterRole(member.uid, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado para ${member.name}.')),
      );
    } catch (error) {
      _showError(_readableError(error));
    } finally {
      if (mounted) setState(() => _updatingRoleUids.remove(member.uid));
    }
  }

  Future<void> _removeRecruiter({
    required RecruiterRepository repository,
    required String uid,
    required String name,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshabilitar reclutador'),
        content: Text(
          '¿Quieres deshabilitar a $name? '
          'La cuenta quedará fuera del equipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deshabilitar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _removingUids.add(uid));
    try {
      await repository.removeRecruiter(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name fue deshabilitado.')));
    } catch (error) {
      _showError(_readableError(error));
    } finally {
      if (mounted) setState(() => _removingUids.remove(uid));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableError(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Error de backend: ${error.code}.';
    }
    return error.toString();
  }

  String _roleLabel(RecruiterRole role) {
    switch (role) {
      case RecruiterRole.admin:
        return 'Administrador';
      case RecruiterRole.recruiter:
        return 'Reclutador';
      case RecruiterRole.hiringManager:
        return 'Hiring Manager';
      case RecruiterRole.externalEvaluator:
        return 'Evaluador externo';
      case RecruiterRole.viewer:
        return 'Solo lectura';
      case RecruiterRole.legal:
        return 'Legal';
      case RecruiterRole.auditor:
        return 'Auditoría';
    }
  }

  String _statusLabel(RecruiterStatus status) {
    switch (status) {
      case RecruiterStatus.active:
        return 'Activo';
      case RecruiterStatus.invited:
        return 'Invitado';
      case RecruiterStatus.disabled:
        return 'Deshabilitado';
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.isUpdatingRole,
    required this.isRemoving,
    required this.roleLabel,
    required this.statusLabel,
    this.onChangeRole,
    this.onRemove,
  });

  final Recruiter member;
  final bool isCurrentUser;
  final bool isUpdatingRole;
  final bool isRemoving;
  final String roleLabel;
  final String statusLabel;
  final VoidCallback? onChangeRole;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase()),
        ),
        title: Text(member.name.isEmpty ? member.email : member.name),
        subtitle: Text(
          '${member.email}\nRol: $roleLabel · Estado: $statusLabel',
        ),
        isThreeLine: true,
        trailing: isCurrentUser
            ? const Chip(label: Text('Tú'))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Cambiar rol',
                    onPressed: isUpdatingRole || isRemoving
                        ? null
                        : onChangeRole,
                    icon: isUpdatingRole
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_accounts_outlined),
                  ),
                  IconButton(
                    tooltip: 'Deshabilitar',
                    onPressed: isUpdatingRole || isRemoving ? null : onRemove,
                    icon: isRemoving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_outlined),
                  ),
                ],
              ),
      ),
    );
  }
}
