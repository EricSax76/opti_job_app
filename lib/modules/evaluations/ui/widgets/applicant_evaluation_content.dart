import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/evaluations/cubits/evaluation_summary_cubit.dart';
import 'package:opti_job_app/modules/evaluations/logic/applicant_evaluation_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/ai_recommendation_card.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/approval_flow_widget.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/evaluation_summary_card.dart';

class ApplicantEvaluationContent extends StatelessWidget {
  const ApplicantEvaluationContent({
    super.key,
    required this.state,
    required this.actor,
    required this.isLoadingTemplate,
    required this.isRequestingApproval,
    required this.onNewEvaluation,
    required this.onRequestApproval,
    required this.onRefresh,
    required this.onOverrideAiEvaluation,
    required this.onEvaluationTap,
    required this.onApprovalDecision,
    required this.onPermissionDeniedForOverride,
  });

  final EvaluationSummaryState state;
  final ApplicantEvaluationActor? actor;
  final bool isLoadingTemplate;
  final bool isRequestingApproval;
  final VoidCallback onNewEvaluation;
  final VoidCallback onRequestApproval;
  final VoidCallback onRefresh;
  final VoidCallback onOverrideAiEvaluation;
  final ValueChanged<Evaluation> onEvaluationTap;
  final Future<void> Function(
    String approvalId,
    ApprovalStatus status,
    String? notes,
  )?
  onApprovalDecision;
  final VoidCallback onPermissionDeniedForOverride;

  @override
  Widget build(BuildContext context) {
    final latestAiEvaluation = ApplicantEvaluationLogic.latestAiEvaluation(
      state.evaluations,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationActionBar(
          canScore: actor?.canScore == true,
          canRequestApprovals: actor?.canRequestApprovals == true,
          isLoadingTemplate: isLoadingTemplate,
          isRequestingApproval: isRequestingApproval,
          onNewEvaluation: onNewEvaluation,
          onRequestApproval: onRequestApproval,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 8),
        if (state.status == EvaluationSummaryStatus.loading)
          const LinearProgressIndicator(),
        if (state.status == EvaluationSummaryStatus.failure)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('No se pudieron cargar evaluaciones y aprobaciones.'),
          ),
        if (state.status == EvaluationSummaryStatus.success)
          _EvaluationSummaryContent(
            evaluations: state.evaluations,
            approvals: state.approvals,
            latestAiEvaluation: latestAiEvaluation,
            canScore: actor?.canScore == true,
            currentActorUid: actor?.uid,
            onOverrideAiEvaluation: onOverrideAiEvaluation,
            onEvaluationTap: onEvaluationTap,
            onApprovalDecision: onApprovalDecision,
            onPermissionDeniedForOverride: onPermissionDeniedForOverride,
          ),
      ],
    );
  }
}

class _EvaluationActionBar extends StatelessWidget {
  const _EvaluationActionBar({
    required this.canScore,
    required this.canRequestApprovals,
    required this.isLoadingTemplate,
    required this.isRequestingApproval,
    required this.onNewEvaluation,
    required this.onRequestApproval,
    required this.onRefresh,
  });

  final bool canScore;
  final bool canRequestApprovals;
  final bool isLoadingTemplate;
  final bool isRequestingApproval;
  final VoidCallback onNewEvaluation;
  final VoidCallback onRequestApproval;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: (!canScore || isLoadingTemplate) ? null : onNewEvaluation,
          icon: isLoadingTemplate
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.rate_review_outlined),
          label: const Text('Nueva evaluación'),
        ),
        OutlinedButton.icon(
          onPressed: (!canRequestApprovals || isRequestingApproval)
              ? null
              : onRequestApproval,
          icon: isRequestingApproval
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fact_check_outlined),
          label: const Text('Solicitar aprobación'),
        ),
        IconButton(
          tooltip: 'Recargar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _EvaluationSummaryContent extends StatelessWidget {
  const _EvaluationSummaryContent({
    required this.evaluations,
    required this.approvals,
    required this.latestAiEvaluation,
    required this.canScore,
    required this.currentActorUid,
    required this.onOverrideAiEvaluation,
    required this.onEvaluationTap,
    required this.onApprovalDecision,
    required this.onPermissionDeniedForOverride,
  });

  final List<Evaluation> evaluations;
  final List<Approval> approvals;
  final Evaluation? latestAiEvaluation;
  final bool canScore;
  final String? currentActorUid;
  final VoidCallback onOverrideAiEvaluation;
  final ValueChanged<Evaluation> onEvaluationTap;
  final Future<void> Function(
    String approvalId,
    ApprovalStatus status,
    String? notes,
  )?
  onApprovalDecision;
  final VoidCallback onPermissionDeniedForOverride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latestAiEvaluation != null) ...[
          AIRecommendationCard(
            aiScore:
                latestAiEvaluation!.aiOriginalScore ??
                latestAiEvaluation!.overallScore,
            aiExplanation:
                (latestAiEvaluation!.aiExplanation ?? '').trim().isEmpty
                ? 'No hay explicación detallada de IA disponible.'
                : latestAiEvaluation!.aiExplanation!.trim(),
            isOverridden: latestAiEvaluation!.aiOverridden,
            onOverride: canScore
                ? onOverrideAiEvaluation
                : onPermissionDeniedForOverride,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Evaluaciones (${evaluations.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (evaluations.isEmpty)
          const Text('Aún no hay evaluaciones para esta candidatura.')
        else
          ...evaluations.map(
            (evaluation) => EvaluationSummaryCard(
              evaluation: evaluation,
              onTap: () => onEvaluationTap(evaluation),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Aprobaciones (${approvals.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (approvals.isEmpty)
          const Text('No hay solicitudes de aprobación abiertas.')
        else
          ...approvals.map(
            (approval) => ApprovalFlowWidget(
              approval: approval,
              currentUid: currentActorUid,
              onDecision: onApprovalDecision == null
                  ? null
                  : (status, notes) =>
                        onApprovalDecision!(approval.id, status, notes),
            ),
          ),
      ],
    );
  }
}
