import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/compliance_status_pills.dart';

class ConsentRecordsTab extends StatelessWidget {
  const ConsentRecordsTab({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
              (doc) => ConsentRecord.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ),
            )
            .toList(growable: false);

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
                      rows: records
                          .map((record) {
                            final isExpired =
                                record.expiresAt != null &&
                                record.expiresAt!.isBefore(DateTime.now());
                            return DataRow(
                              cells: [
                                DataCell(Text(shortUid(record.candidateUid))),
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
                                  ConsentStatusIndicator(
                                    granted: record.granted && !isExpired,
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
