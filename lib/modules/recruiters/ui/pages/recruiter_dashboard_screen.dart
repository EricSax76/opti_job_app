import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';

class RecruiterDashboardScreen extends StatelessWidget {
  const RecruiterDashboardScreen({super.key, required this.recruiterUid});

  final String recruiterUid;

  @override
  Widget build(BuildContext context) {
    final recruiter = context.watch<RecruiterAuthCubit>().state.recruiter;
    if (recruiter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Reclutador')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/recruiter-login'),
            child: const Text('Iniciar sesión'),
          ),
        ),
      );
    }

    final normalizedRouteUid = recruiterUid.trim();
    if (normalizedRouteUid.isNotEmpty && normalizedRouteUid != recruiter.uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go('/recruiter/${recruiter.uid}/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rbac = context.read<RbacService>();
    final hasCompanyAssociation = recruiter.hasCompanyAssociation;
    final canManageOffers = rbac.canManageOffers(recruiter);
    final canScore = rbac.canScore(recruiter);
    final canViewReports = rbac.canViewReports(recruiter);
    final canManageTeam = rbac.canManageTeam(recruiter);
    final canInviteMembers = rbac.canInviteMembers(recruiter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Reclutador'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<RecruiterAuthCubit>().logout();
              if (context.mounted) context.go('/recruiter-login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hola, ${recruiter.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Rol: ${_roleLabel(recruiter)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            hasCompanyAssociation
                ? 'Empresa: ${recruiter.companyId}'
                : 'Empresa: sin vinculación (freelance)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!hasCompanyAssociation) ...[
            const SizedBox(height: 12),
            Text(
              'Tu cuenta está activa como recruiter autónomo. Cuando una empresa te invite y aceptes el código, aquí verás tus permisos RBAC.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PermissionChip(
                label: 'Gestionar ofertas',
                enabled: canManageOffers,
              ),
              _PermissionChip(label: 'Evaluar candidatos', enabled: canScore),
              _PermissionChip(label: 'Ver reportes', enabled: canViewReports),
              _PermissionChip(
                label: 'Gestionar equipo',
                enabled: canManageTeam,
              ),
              _PermissionChip(
                label: 'Invitar miembros',
                enabled: canInviteMembers,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accesos rápidos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: canViewReports && hasCompanyAssociation
                            ? () => context.go(
                                '/company/${recruiter.companyId}/analytics',
                              )
                            : null,
                        icon: const Icon(Icons.query_stats),
                        label: const Text('Analytics'),
                      ),
                      OutlinedButton.icon(
                        onPressed: canViewReports && hasCompanyAssociation
                            ? () => context.go(
                                '/company/${recruiter.companyId}/consents',
                              )
                            : null,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Consentimientos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(Recruiter recruiter) {
    switch (recruiter.role.name) {
      case 'admin':
        return 'Administrador';
      case 'recruiter':
        return 'Reclutador';
      case 'viewer':
        return 'Solo lectura';
      case 'hiringManager':
        return 'Hiring Manager';
      case 'externalEvaluator':
        return 'Evaluador Externo';
      case 'legal':
        return 'Legal';
      case 'auditor':
        return 'Auditoría';
      default:
        return recruiter.role.name;
    }
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = enabled
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = enabled ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Chip(
      label: Text(label),
      avatar: Icon(
        enabled ? Icons.check_circle_outline : Icons.block_outlined,
        size: 16,
        color: fg,
      ),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg),
    );
  }
}
