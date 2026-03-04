import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';

class ConsentManagementScreen extends StatelessWidget {
  const ConsentManagementScreen({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Consentimientos (RGPD)')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('consentRecords')
            .where('companyId', isEqualTo: companyId)
            .orderBy('grantedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const StateMessage(
              title: 'Error',
              message: 'No se pudieron cargar los consentimientos.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs
              .map(
                (d) => ConsentRecord.fromJson(
                  d.data() as Map<String, dynamic>,
                  id: d.id,
                ),
              )
              .toList();

          if (records.isEmpty) {
            return const StateMessage(
              title: 'Sin registros',
              message: 'No hay registros de consentimiento.',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(uiSpacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Consentimientos RGPD',
                  subtitle: 'Estado de permisos y vigencia por candidato.',
                  titleFontSize: 22,
                ),
                const SizedBox(height: uiSpacing16),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(uiSpacing12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Candidato')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Base Legal')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Expiración')),
                          DataColumn(label: Text('Estado')),
                        ],
                        rows: records.map((record) {
                          final isExpired =
                              record.expiresAt != null &&
                              record.expiresAt!.isBefore(DateTime.now());
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(record.candidateUid.substring(0, 8)),
                              ),
                              DataCell(Text(record.type)),
                              DataCell(Text(record.legalBasis.name)),
                              DataCell(
                                Text(
                                  record.grantedAt != null
                                      ? DateFormat(
                                          'd MMM yyyy',
                                        ).format(record.grantedAt!)
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  record.expiresAt != null
                                      ? DateFormat(
                                          'd MMM yyyy',
                                        ).format(record.expiresAt!)
                                      : '-',
                                ),
                              ),
                              DataCell(
                                _StatusIndicator(
                                  granted: record.granted && !isExpired,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = granted ? scheme.tertiary : scheme.error;
    return InfoPill(
      label: granted ? 'ACTIVO' : 'REVOCADO/EXPIRADO',
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}
