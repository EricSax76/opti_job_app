import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class RecruiterPerformanceTable extends StatelessWidget {
  const RecruiterPerformanceTable({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cellStyle = textTheme.bodySmall;
    // Expected format: { uid: { name: '...', evaluations: 50, avgResponseTime: 4.5 } }
    final recruiters = data.entries.toList();

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desempeño del Equipo de Selección',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              columnSpacing: 24,
              columns: [
                DataColumn(label: Text('Reclutador', style: cellStyle)),
                DataColumn(label: Text('Eval.', style: cellStyle)),
                DataColumn(label: Text('Resp. (h)', style: cellStyle)),
              ],
              rows: recruiters.map((entry) {
                final metrics = entry.value as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(metrics['name'] ?? entry.key, style: cellStyle),
                    ),
                    DataCell(
                      Text('${metrics['evaluations']}', style: cellStyle),
                    ),
                    DataCell(
                      Text(
                        '${(metrics['avgResponseTime'] as num?)?.toStringAsFixed(1)}',
                        style: cellStyle,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
