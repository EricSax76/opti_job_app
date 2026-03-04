import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/privacy_notice_dialog.dart';

class CandidatePrivacyPortalScreen extends StatefulWidget {
  const CandidatePrivacyPortalScreen({super.key, required this.candidateUid});

  final String candidateUid;

  @override
  State<CandidatePrivacyPortalScreen> createState() =>
      _CandidatePrivacyPortalScreenState();
}

class _CandidatePrivacyPortalScreenState
    extends State<CandidatePrivacyPortalScreen> {
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

  void _showRequestDialog(BuildContext context, DataRequestType type) {
    final controller = TextEditingController();
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataRequestsCubit>().submitRequest(
                DataRequest(
                  id: '',
                  candidateUid: widget.candidateUid,
                  type: type,
                  description: controller.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  String _dialogTitle(DataRequestType type) {
    if (type == DataRequestType.aiExplanation) {
      return 'Explicación humana de IA';
    }
    return 'Ejercicio de ${_requestTypeLabel(type)}';
  }

  String _dialogDescription(DataRequestType type) {
    if (type == DataRequestType.aiExplanation) {
      return 'Indica qué decisión asistida por IA quieres que revise una persona.';
    }
    return 'Describe brevemente tu solicitud de ${_requestTypeLabel(type)}.';
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
