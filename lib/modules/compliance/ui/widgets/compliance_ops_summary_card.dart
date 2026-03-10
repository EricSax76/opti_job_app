import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';

class ComplianceOpsSummaryCard extends StatelessWidget {
  const ComplianceOpsSummaryCard({
    super.key,
    required this.companyId,
    required this.overdueOpenCount,
  });

  final String companyId;
  final int overdueOpenCount;

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());
    final docId = '${companyId.trim()}:$dateKey';
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('complianceOpsDaily')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppCard(
            child: Text(
              'No se pudo cargar el dashboard operativo de compliance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final payload = snapshot.data?.data() ?? const <String, dynamic>{};
        final viewData = ComplianceOpsSummaryViewData.fromPayload(
          payload,
          overdueOpenCount: overdueOpenCount,
        );

        return AppCard(
          padding: const EdgeInsets.all(uiSpacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observabilidad operativa (UTC $dateKey)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: uiSpacing8),
              Wrap(
                spacing: uiSpacing8,
                runSpacing: uiSpacing8,
                children: [
                  InfoPill(
                    label: 'Procesadas: ${viewData.invocations}',
                    backgroundColor: scheme.primary.withValues(alpha: 0.1),
                    borderColor: scheme.primary.withValues(alpha: 0.25),
                    textColor: scheme.primary,
                  ),
                  InfoPill(
                    label: 'Éxitos: ${viewData.successes}',
                    backgroundColor: scheme.tertiary.withValues(alpha: 0.1),
                    borderColor: scheme.tertiary.withValues(alpha: 0.25),
                    textColor: scheme.tertiary,
                  ),
                  InfoPill(
                    label: 'Errores: ${viewData.errors}',
                    backgroundColor:
                        (viewData.hasErrors ? scheme.error : scheme.outline)
                            .withValues(alpha: 0.1),
                    borderColor:
                        (viewData.hasErrors ? scheme.error : scheme.outline)
                            .withValues(alpha: 0.25),
                    textColor: viewData.hasErrors
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                  InfoPill(
                    label: viewData.avgLatencyMs == null
                        ? 'Latencia media: N/D'
                        : 'Latencia media: ${viewData.avgLatencyMs}ms',
                  ),
                  InfoPill(
                    label: viewData.completedCount == 0
                        ? 'SLA resuelto: N/D'
                        : 'SLA resuelto: ${viewData.slaRate!.toStringAsFixed(1)}%',
                    backgroundColor: viewData.completedOutsideCount > 0
                        ? scheme.error.withValues(alpha: 0.1)
                        : scheme.secondary.withValues(alpha: 0.1),
                    borderColor: viewData.completedOutsideCount > 0
                        ? scheme.error.withValues(alpha: 0.25)
                        : scheme.secondary.withValues(alpha: 0.25),
                    textColor: viewData.completedOutsideCount > 0
                        ? scheme.error
                        : scheme.secondary,
                  ),
                  InfoPill(
                    label: 'Vencidas abiertas: $overdueOpenCount',
                    backgroundColor: viewData.hasOpenOverdue
                        ? scheme.error.withValues(alpha: 0.1)
                        : scheme.outline.withValues(alpha: 0.1),
                    borderColor: viewData.hasOpenOverdue
                        ? scheme.error.withValues(alpha: 0.25)
                        : scheme.outline.withValues(alpha: 0.25),
                    textColor: viewData.hasOpenOverdue
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (viewData.hasAlert) ...[
                const SizedBox(height: uiSpacing8),
                Text(
                  'Alertas activas: ${viewData.alertsLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
