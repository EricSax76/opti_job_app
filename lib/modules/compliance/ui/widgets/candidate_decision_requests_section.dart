import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/compliance/logic/candidate_privacy_portal_logic.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

class CandidateDecisionRequestsSection extends StatelessWidget {
  const CandidateDecisionRequestsSection({
    super.key,
    required this.candidateUid,
    required this.onRequest,
  });

  final String candidateUid;
  final Future<bool> Function({
    required DataRequestType type,
    required String description,
    required String? companyId,
    required String? applicationId,
    Map<String, dynamic> metadata,
  })
  onRequest;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('candidateId', isEqualTo: candidateUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const InlineStateMessage(
            icon: Icons.search_off_outlined,
            message: 'Aún no hay candidaturas para solicitudes contextuales.',
          );
        }

        final contexts = docs
            .map(
              (doc) => CandidateDecisionRequestContext.fromFirestore(
                doc.id,
                doc.data(),
              ),
            )
            .toList(growable: false);
        contexts.sort(
          (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          ),
        );

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contexts.length,
          separatorBuilder: (_, _) => const SizedBox(height: uiSpacing8),
          itemBuilder: (context, index) {
            final item = contexts[index];
            return AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.offerTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: uiSpacing4),
                  InfoPill(
                    label: 'Estado: ${item.statusLabel}',
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  if (item.aiExplanation != null &&
                      item.aiExplanation!.trim().isNotEmpty) ...[
                    const SizedBox(height: uiSpacing8),
                    const AiGeneratedLabel(compact: true),
                    const SizedBox(height: uiSpacing8),
                    Text(
                      item.aiExplanation!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: uiSpacing8),
                  Wrap(
                    spacing: uiSpacing8,
                    runSpacing: uiSpacing8,
                    children: [
                      if (item.aiExplanation != null &&
                          item.aiExplanation!.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await onRequest(
                              type: DataRequestType.aiExplanation,
                              description:
                                  'Solicito revisión humana de la decisión IA asociada a la candidatura ${item.id}.',
                              companyId: item.companyId,
                              applicationId: item.id,
                              metadata: {
                                'requestSource': 'privacy_portal_card',
                              },
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Solicitud de explicación humana enviada.'
                                      : 'No se pudo enviar la solicitud.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.psychology_outlined, size: 18),
                          label: const Text('Solicitar revisión IA'),
                        ),
                      if (item.isFinalist)
                        FilledButton.icon(
                          onPressed: () async {
                            final ok = await onRequest(
                              type: DataRequestType.salaryComparison,
                              description:
                                  'Solicito información comparativa de niveles salariales por sexo para puestos de igual valor (candidatura ${item.id}).',
                              companyId: item.companyId,
                              applicationId: item.id,
                              metadata: {
                                'requestSource': 'privacy_portal_card',
                                'statusAtRequest': item.status,
                              },
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Solicitud de comparativa salarial enviada.'
                                      : 'No se pudo enviar la solicitud.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.balance_outlined, size: 18),
                          label: const Text('Solicitar comparativa salarial'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
