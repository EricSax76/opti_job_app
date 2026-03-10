import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';
import 'package:opti_job_app/modules/compliance/logic/data_request_labels.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/compliance_ops_summary_card.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/compliance_status_pills.dart';

class ComplianceDataRequestsTab extends StatelessWidget {
  const ComplianceDataRequestsTab({
    super.key,
    required this.companyId,
    required this.processingRequestIds,
    required this.onProcessRequest,
  });

  final String companyId;
  final Set<String> processingRequestIds;
  final Future<void> Function(DataRequest request) onProcessRequest;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dataRequests')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const StateMessage(
            title: 'Error',
            message: 'No se pudieron cargar las solicitudes de privacidad.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests =
            snapshot.data?.docs
                .map((doc) => DataRequest.fromJson(doc.data(), id: doc.id))
                .toList(growable: false) ??
            const <DataRequest>[];

        final overdueCount = requests
            .where((request) => isDataRequestOverdue(request))
            .length;
        final hasRequests = requests.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.all(uiSpacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Solicitudes ARSULIPO / AI Act',
                subtitle:
                    'Gestiona respuestas con trazabilidad y SLA de 30 días. Vencidas: $overdueCount.',
                titleFontSize: 22,
              ),
              const SizedBox(height: uiSpacing16),
              ComplianceOpsSummaryCard(
                companyId: companyId,
                overdueOpenCount: overdueCount,
              ),
              const SizedBox(height: uiSpacing16),
              Expanded(
                child: hasRequests
                    ? _ComplianceDataRequestsTable(
                        requests: requests,
                        processingRequestIds: processingRequestIds,
                        onProcessRequest: onProcessRequest,
                      )
                    : const StateMessage(
                        title: 'Sin solicitudes',
                        message:
                            'No hay solicitudes ARSULIPO/AI Act para esta empresa.',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComplianceDataRequestsTable extends StatelessWidget {
  const _ComplianceDataRequestsTable({
    required this.requests,
    required this.processingRequestIds,
    required this.onProcessRequest,
  });

  final List<DataRequest> requests;
  final Set<String> processingRequestIds;
  final Future<void> Function(DataRequest request) onProcessRequest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Solicitud')),
            DataColumn(label: Text('Candidato')),
            DataColumn(label: Text('Creada')),
            DataColumn(label: Text('SLA')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acción')),
          ],
          rows: requests
              .map((request) {
                final isProcessing = processingRequestIds.contains(request.id);
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DataRequestLabels.typeLabel(request.type),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (request.applicationId != null)
                              Text(
                                'Candidatura: ${request.applicationId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(shortUid(request.candidateUid))),
                    DataCell(
                      Text(
                        request.createdAt != null
                            ? DateFormat(
                                'd MMM yyyy',
                              ).format(request.createdAt!)
                            : '-',
                      ),
                    ),
                    DataCell(DataRequestSlaPill(request: request)),
                    DataCell(
                      DataRequestStatusIndicator(status: request.status),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () => onProcessRequest(request),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Gestionar'),
                        ),
                      ),
                    ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}
