import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/compliance/logic/data_request_labels.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/compliance_status_pills.dart';

class CandidatePrivacyRequestTile extends StatelessWidget {
  const CandidatePrivacyRequestTile({super.key, required this.request});

  final DataRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing8),
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Text(DataRequestLabels.typeLabel(request.type)),
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
        trailing: DataRequestStatusIndicator(status: request.status),
      ),
    );
  }
}
