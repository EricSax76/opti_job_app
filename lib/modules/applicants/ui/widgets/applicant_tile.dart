import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/application_status.dart';
import 'package:opti_job_app/modules/applications/ui/widgets/application_status_badge.dart';

class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    super.key,
    required this.application,
    this.onTap,
    this.onStatusChanged,
    this.onStartInterview,
  });

  final Application application;
  final VoidCallback? onTap;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onStartInterview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final border = colorScheme.outline;
    final avatarBg = colorScheme.primary;
    final avatarFg = colorScheme.onPrimary;
    final isAnonymousScreening = shouldAnonymizeApplication(application);
    final displayName = isAnonymousScreening
        ? buildAnonymizedCandidateLabel(
            application.candidateUid,
            anonymizedLabel: application.anonymizedLabel,
          )
        : (application.candidateName ??
              application.candidateEmail ??
              application.candidateUid);

    final subtitleParts = <String>[];
    if (!isAnonymousScreening &&
        application.candidateEmail != null &&
        application.candidateEmail!.isNotEmpty) {
      subtitleParts.add(application.candidateEmail!);
    } else if (isAnonymousScreening) {
      subtitleParts.add('Identidad oculta hasta etapas avanzadas');
    }
    subtitleParts.add(
      'Estado: ${ApplicationStatus.fromString(application.status).label}',
    );

    final stageName = application.pipelineStageName?.trim();
    final matchScore = application.matchScore;
    final knockoutPassed = application.knockoutPassed;
    final hasAtsMeta =
        (stageName != null && stageName.isNotEmpty) ||
        matchScore != null ||
        knockoutPassed != null;

    final canChangeStatus = onStatusChanged != null && onStartInterview != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          foregroundColor: avatarFg,
          child: Text(_initials(displayName)),
        ),
        title: Text(
          displayName,
          style: TextStyle(color: ink, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleParts.join(' • '),
              style: TextStyle(color: muted, height: 1.35),
            ),
            if (hasAtsMeta) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (stageName != null && stageName.isNotEmpty)
                    _ApplicantMetaBadge(
                      icon: Icons.view_kanban_outlined,
                      label: 'Etapa: $stageName',
                      color: muted,
                      borderColor: border,
                    ),
                  if (matchScore != null)
                    _ApplicantMetaBadge(
                      icon: Icons.auto_graph_outlined,
                      label: 'Match: ${matchScore.toStringAsFixed(0)}%',
                      color: colorScheme.primary,
                      borderColor: colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  if (knockoutPassed != null)
                    _ApplicantMetaBadge(
                      icon: knockoutPassed
                          ? Icons.task_alt_outlined
                          : Icons.warning_amber_rounded,
                      label: knockoutPassed
                          ? 'Knockout: Aprobado'
                          : 'Knockout: Revisar',
                      color: knockoutPassed
                          ? colorScheme.tertiary
                          : colorScheme.error,
                      borderColor: knockoutPassed
                          ? colorScheme.tertiary.withValues(alpha: 0.35)
                          : colorScheme.error.withValues(alpha: 0.35),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: !canChangeStatus
            ? null
            : PopupMenuButton<String>(
                tooltip: 'Actualizar estado',
                onSelected: (value) {
                  if (value == ApplicationStatus.interview.name) {
                    onStartInterview?.call();
                  } else {
                    onStatusChanged?.call(value);
                  }
                },
                itemBuilder: (context) {
                  return ApplicationStatus.values
                      .where(
                        (s) =>
                            s != ApplicationStatus.pending &&
                            s != ApplicationStatus.unknown &&
                            s != ApplicationStatus.withdrawn,
                      )
                      .map((status) {
                        final isSelected = status.name == application.status;
                        return PopupMenuItem<String>(
                          value: status.name,
                          child: Row(
                            children: [
                              if (isSelected)
                                const Icon(Icons.check, size: 16)
                              else
                                const SizedBox(width: 16),
                              Text(status.label),
                            ],
                          ),
                        );
                      })
                      .toList();
                },
                child: ApplicationStatusBadge.fromString(application.status),
              ),
      ),
    );
  }
}

class _ApplicantMetaBadge extends StatelessWidget {
  const _ApplicantMetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, height: 1.1),
          ),
        ],
      ),
    );
  }
}

String _initials(String label) {
  final raw = label.trim();
  if (raw.isEmpty) {
    return '?';
  }
  return raw.substring(0, 1).toUpperCase();
}
