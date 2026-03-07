import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/privacy_notice_dialog.dart';

class CandidatePrivacyPortalScreen extends StatefulWidget {
  const CandidatePrivacyPortalScreen({
    super.key,
    required this.candidateUid,
    this.enableDecisionContextSection = true,
  });

  final String candidateUid;
  final bool enableDecisionContextSection;

  @override
  State<CandidatePrivacyPortalScreen> createState() =>
      _CandidatePrivacyPortalScreenState();
}

class _CandidatePrivacyPortalScreenState
    extends State<CandidatePrivacyPortalScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    context.read<DataRequestsCubit>().subscribeToRequests(widget.candidateUid);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Privacidad'),
        actions: [
          IconButton(
            tooltip: 'Exportar mis datos',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _isExporting ? null : () => _exportCandidateData(),
          ),
          IconButton(
            tooltip: 'Información de privacidad',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const PrivacyNoticeDialog(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(uiSpacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Tus derechos ARSULIPO',
              subtitle:
                  'Gestiona derechos RGPD y solicita explicación humana de decisiones asistidas por IA.',
              titleFontSize: 22,
            ),
            const SizedBox(height: uiSpacing8),
            Text(
              'Como titular de los datos, puedes ejercer acceso, rectificación, supresión (bloqueo), limitación, portabilidad, oposición y solicitar explicación humana de decisiones de IA.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: uiSpacing8),
            Text(
              'También puedes exportar tus datos con notas del reclutador desde el botón de descarga.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: uiSpacing16),
            Wrap(
              spacing: uiSpacing8,
              runSpacing: uiSpacing8,
              children: DataRequestType.values
                  .map(
                    (type) => ActionChip(
                      label: Text(_requestTypeLabel(type)),
                      onPressed: () => _showRequestDialog(context, type),
                    ),
                  )
                  .toList(),
            ),
            if (widget.enableDecisionContextSection) ...[
              const SizedBox(height: uiSpacing24),
              const SectionHeader(
                title: 'Decisiones IA y solicitudes contextuales',
                subtitle:
                    'Solicita revisión humana de decisiones de IA y comparativa salarial cuando seas finalista.',
                titleFontSize: 20,
              ),
              const SizedBox(height: uiSpacing12),
              _CandidateDecisionRequestsSection(
                candidateUid: widget.candidateUid,
                onRequest:
                    ({
                      required DataRequestType type,
                      required String description,
                      required String? companyId,
                      required String? applicationId,
                      Map<String, dynamic> metadata = const {},
                    }) async {
                      return context.read<DataRequestsCubit>().submitRequest(
                        DataRequest(
                          id: '',
                          candidateUid: widget.candidateUid,
                          type: type,
                          description: description,
                          companyId: companyId,
                          applicationId: applicationId,
                          metadata: metadata,
                        ),
                      );
                    },
              ),
            ],
            const SizedBox(height: uiSpacing32),
            const SectionHeader(
              title: 'Tus solicitudes',
              subtitle: 'Seguimiento del estado de tus peticiones.',
              titleFontSize: 20,
            ),
            const SizedBox(height: uiSpacing16),
            BlocBuilder<DataRequestsCubit, DataRequestsState>(
              builder: (context, state) {
                if (state.status == DataRequestsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == DataRequestsStatus.failure) {
                  return InlineStateMessage(
                    icon: Icons.error_outline,
                    message:
                        state.errorMessage ??
                        'No se pudieron cargar tus solicitudes.',
                  );
                }
                if (state.requests.isEmpty) {
                  return const InlineStateMessage(
                    icon: Icons.inbox_outlined,
                    message: 'No tienes solicitudes registradas.',
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.requests.length,
                  itemBuilder: (context, index) {
                    final req = state.requests[index];
                    return _RequestTile(request: req);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCandidateData() async {
    setState(() => _isExporting = true);
    try {
      final payload = await context
          .read<DataRequestRepository>()
          .exportCandidateData();
      final summary = _ExportSummary.fromPayload(payload);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exportación de datos lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Candidaturas: ${summary.applicationsCount}'),
              Text('Consentimientos: ${summary.consentsCount}'),
              Text('Solicitudes de privacidad: ${summary.requestsCount}'),
              Text('Notas de reclutador: ${summary.notesCount}'),
              if (summary.exportedAt != null)
                Text('Generado: ${summary.exportedAt!}'),
              const SizedBox(height: uiSpacing12),
              const Text(
                'Puedes copiar el JSON completo para tu solicitud ARSULIPO.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent(
                      '  ',
                    ).convert(summary.rawPayload),
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON copiado al portapapeles.'),
                  ),
                );
              },
              child: const Text('Copiar JSON'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo exportar tus datos (${error.code}). Inténtalo de nuevo.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo exportar tus datos.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showRequestDialog(BuildContext context, DataRequestType type) {
    final controller = TextEditingController();
    final applicationController = TextEditingController();
    final companyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_dialogTitle(type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_dialogDescription(type)),
            const SizedBox(height: uiSpacing8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (type == DataRequestType.aiExplanation ||
                type == DataRequestType.salaryComparison) ...[
              const SizedBox(height: uiSpacing8),
              TextField(
                controller: applicationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID de candidatura (opcional)',
                ),
              ),
              const SizedBox(height: uiSpacing8),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID de empresa (opcional)',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<DataRequestsCubit>().submitRequest(
                DataRequest(
                  id: '',
                  candidateUid: widget.candidateUid,
                  type: type,
                  description: controller.text,
                  applicationId: applicationController.text.trim().isEmpty
                      ? null
                      : applicationController.text.trim(),
                  companyId: companyController.text.trim().isEmpty
                      ? null
                      : companyController.text.trim(),
                ),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Solicitud enviada correctamente.'
                        : 'No se pudo enviar la solicitud.',
                  ),
                ),
              );
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  String _dialogTitle(DataRequestType type) {
    return switch (type) {
      DataRequestType.aiExplanation => 'Explicación humana de IA',
      DataRequestType.salaryComparison => 'Comparativa salarial por sexo',
      _ => 'Ejercicio de ${_requestTypeLabel(type)}',
    };
  }

  String _dialogDescription(DataRequestType type) {
    return switch (type) {
      DataRequestType.aiExplanation =>
        'Indica qué decisión asistida por IA quieres que revise una persona.',
      DataRequestType.salaryComparison =>
        'Solicita niveles retributivos medios desglosados por sexo para puestos de igual valor.',
      _ => 'Describe brevemente tu solicitud de ${_requestTypeLabel(type)}.',
    };
  }

  String _requestTypeLabel(DataRequestType type) {
    return switch (type) {
      DataRequestType.access => 'ACCESO',
      DataRequestType.rectification => 'RECTIFICACIÓN',
      DataRequestType.deletion => 'SUPRESIÓN',
      DataRequestType.limitation => 'LIMITACIÓN',
      DataRequestType.portability => 'PORTABILIDAD',
      DataRequestType.opposition => 'OPOSICIÓN',
      DataRequestType.aiExplanation => 'EXPLICACIÓN IA',
      DataRequestType.salaryComparison => 'COMPARATIVA SALARIAL',
    };
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final DataRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing8),
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Text(_typeLabel(request.type)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.description),
            if (request.createdAt != null)
              Text(
                'Solicitado: ${DateFormat('d MMM yyyy').format(request.createdAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            if (request.dueAt != null)
              Text(
                'SLA límite: ${DateFormat('d MMM yyyy').format(request.dueAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            if (request.processedAt != null)
              Text(
                'Procesado: ${DateFormat('d MMM yyyy').format(request.processedAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            if (request.response != null && request.response!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: uiSpacing4),
                child: Text(
                  'Respuesta empresa: ${request.response!.trim()}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: _StatusBadge(status: request.status),
      ),
    );
  }

  String _typeLabel(DataRequestType type) {
    return switch (type) {
      DataRequestType.access => 'ACCESO',
      DataRequestType.rectification => 'RECTIFICACIÓN',
      DataRequestType.deletion => 'SUPRESIÓN',
      DataRequestType.limitation => 'LIMITACIÓN',
      DataRequestType.portability => 'PORTABILIDAD',
      DataRequestType.opposition => 'OPOSICIÓN',
      DataRequestType.aiExplanation => 'EXPLICACIÓN IA',
      DataRequestType.salaryComparison => 'COMPARATIVA SALARIAL',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DataRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color = scheme.outline;
    if (status == DataRequestStatus.completed) color = scheme.tertiary;
    if (status == DataRequestStatus.processing) color = scheme.primary;
    if (status == DataRequestStatus.denied) color = scheme.error;

    return InfoPill(
      label: status.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      textColor: color,
    );
  }
}

class _CandidateDecisionRequestsSection extends StatelessWidget {
  const _CandidateDecisionRequestsSection({
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
            .map((doc) => _RequestContext.fromFirestore(doc.id, doc.data()))
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

class _RequestContext {
  const _RequestContext({
    required this.id,
    required this.offerTitle,
    required this.status,
    required this.companyId,
    required this.aiExplanation,
    required this.updatedAt,
  });

  final String id;
  final String offerTitle;
  final String status;
  final String? companyId;
  final String? aiExplanation;
  final DateTime? updatedAt;

  bool get isFinalist =>
      status == 'offered' ||
      status == 'hired' ||
      status == 'interviewing' ||
      status == 'finalist';

  String get statusLabel {
    if (status.isEmpty) return 'Sin estado';
    return status.toUpperCase();
  }

  factory _RequestContext.fromFirestore(String id, Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final aiMatch =
        (json['aiMatchResult'] as Map<String, dynamic>?) ?? const {};
    final rawStatus = (json['status'] as String? ?? '').trim().toLowerCase();
    final title = (json['jobOfferTitle'] as String?)?.trim();
    final jobOfferId = (json['job_offer_id'] ?? json['jobOfferId'])?.toString();
    final company = (json['company_uid'] ?? json['companyUid'])?.toString();

    return _RequestContext(
      id: id,
      offerTitle: (title != null && title.isNotEmpty)
          ? title
          : 'Candidatura ${jobOfferId ?? id}',
      status: rawStatus,
      companyId: (company == null || company.trim().isEmpty)
          ? null
          : company.trim(),
      aiExplanation: aiMatch['explanation'] as String?,
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class _ExportSummary {
  const _ExportSummary({
    required this.rawPayload,
    required this.applicationsCount,
    required this.consentsCount,
    required this.notesCount,
    required this.requestsCount,
    required this.exportedAt,
  });

  final Map<String, dynamic> rawPayload;
  final int applicationsCount;
  final int consentsCount;
  final int notesCount;
  final int requestsCount;
  final String? exportedAt;

  factory _ExportSummary.fromPayload(Map<String, dynamic> payload) {
    int countOf(String key) {
      final raw = payload[key];
      if (raw is List) return raw.length;
      return 0;
    }

    return _ExportSummary(
      rawPayload: payload,
      applicationsCount: countOf('applications'),
      consentsCount: countOf('consents'),
      notesCount: countOf('candidateNotes'),
      requestsCount: countOf('dataRequests'),
      exportedAt: payload['exportedAt']?.toString(),
    );
  }
}
