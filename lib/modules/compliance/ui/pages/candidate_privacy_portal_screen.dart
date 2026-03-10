import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/logic/candidate_privacy_portal_logic.dart';
import 'package:opti_job_app/modules/compliance/logic/data_request_labels.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/candidate_decision_requests_section.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/candidate_privacy_portal_dialogs.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/candidate_privacy_request_tile.dart';
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
            onPressed: _isExporting ? null : _exportCandidateData,
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
                      label: Text(DataRequestLabels.typeLabel(type)),
                      onPressed: () => _showRequestDialog(type),
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
              CandidateDecisionRequestsSection(
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
                    return CandidatePrivacyRequestTile(
                      request: state.requests[index],
                    );
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
      final summary = CandidatePrivacyExportSummary.fromPayload(payload);
      if (!mounted) return;

      await showCandidatePrivacyExportDialog(context, summary: summary);
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

  Future<void> _showRequestDialog(DataRequestType type) async {
    final input = await showCandidatePrivacyRequestDialog(context, type: type);
    if (!mounted || input == null) return;

    final ok = await context.read<DataRequestsCubit>().submitRequest(
      DataRequest(
        id: '',
        candidateUid: widget.candidateUid,
        type: type,
        description: input.description,
        applicationId: input.applicationId,
        companyId: input.companyId,
      ),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Solicitud enviada correctamente.'
              : 'No se pudo enviar la solicitud.',
        ),
      ),
    );
  }
}
