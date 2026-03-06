import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_cubit.dart';

class PipelineCandidateCard extends StatelessWidget {
  const PipelineCandidateCard({super.key, required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: application.id,
      onDragStarted: () => context.read<PipelineBoardCubit>().onDragStart(),
      onDragEnd: (details) => context.read<PipelineBoardCubit>().onDragEnd(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(uiTileRadius),
        child: SizedBox(
          width: 250,
          child: _CardContent(application: application, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardContent(application: application),
      ),
      child: _CardContent(application: application),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.application, this.isDragging = false});

  final Application application;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAnonymousScreening = shouldAnonymizeApplication(application);
    final displayName = isAnonymousScreening
        ? buildAnonymizedCandidateLabel(
            application.candidateUid,
            anonymizedLabel: application.anonymizedLabel,
          )
        : (application.candidateName ?? 'Desconocido');
    final displayEmail = isAnonymousScreening
        ? 'Identidad oculta en criba inicial'
        : (application.candidateEmail ?? '');

    return AppCard(
      borderRadius: uiTileRadius,
      borderColor: isDragging
          ? colorScheme.primary
          : colorScheme.outlineVariant,
      boxShadow: isDragging ? null : uiShadowSm,
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    !isAnonymousScreening &&
                        application.candidateAvatarUrl != null
                    ? NetworkImage(application.candidateAvatarUrl!)
                    : null,
                child:
                    isAnonymousScreening ||
                        application.candidateAvatarUrl == null
                    ? Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: uiSpacing12),
              Expanded(
                child: Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          Text(
            displayEmail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (application.matchScore != null) ...[
            const SizedBox(height: uiSpacing12),
            InfoPill(
              label: 'Match: ${application.matchScore?.toStringAsFixed(0)}%',
              backgroundColor:
                  (application.matchScore! > 80
                          ? colorScheme.tertiary
                          : colorScheme.secondary)
                      .withValues(alpha: 0.15),
              borderColor:
                  (application.matchScore! > 80
                          ? colorScheme.tertiary
                          : colorScheme.secondary)
                      .withValues(alpha: 0.3),
              textColor: application.matchScore! > 80
                  ? colorScheme.tertiary
                  : colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
