import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

class ConsentManagementScreen extends StatefulWidget {
  const ConsentManagementScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<ConsentManagementScreen> createState() =>
      _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  final Set<String> _processingRequestIds = <String>{};
  static const Set<RecruiterRole> _salaryBenchmarkAllowedRoles = {
    RecruiterRole.admin,
    RecruiterRole.recruiter,
  };

  @override
  Widget build(BuildContext context) {
    final canManageSalaryBenchmarks = _canManageSalaryBenchmarks(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Cumplimiento (RGPD/AI Act)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Consentimientos'),
              Tab(text: 'Solicitudes'),
              Tab(text: 'Benchmarks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ConsentRecordsTab(),
            const _DataRequestsTab(),
            _SalaryBenchmarksTab(
              companyId: widget.companyId,
              canManage: canManageSalaryBenchmarks,
            ),
          ],
        ),
      ),
    );
  }

  bool _canManageSalaryBenchmarks(BuildContext context) {
    final routeCompanyId = widget.companyId.trim();
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid != null && companyUid.trim() == routeCompanyId) {
      return true;
    }

    final recruiter = context.read<RecruiterAuthCubit>().state.recruiter;
    if (recruiter == null || !recruiter.isActive) {
      return false;
    }
    if (recruiter.companyId.trim() != routeCompanyId) {
      return false;
    }
    return _salaryBenchmarkAllowedRoles.contains(recruiter.role);
  }

  Future<void> _processRequest(DataRequest request) async {
    final decision = await showDialog<_RequestDecision>(
      context: context,
      builder: (_) => _ProcessRequestDialog(request: request),
    );

    if (decision == null || !mounted) return;

    setState(() => _processingRequestIds.add(request.id));
    try {
      await context.read<DataRequestRepository>().updateRequestStatus(
        request.id,
        decision.status,
        response: decision.response,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la solicitud: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(request.id));
      }
    }
  }

  bool _isOverdue(DataRequest request) {
    if (request.status == DataRequestStatus.completed ||
        request.status == DataRequestStatus.denied) {
      return false;
    }
    final dueAt = request.dueAt;
    if (dueAt == null) return false;
    return dueAt.isBefore(DateTime.now());
  }

  Widget _buildSlaPill(DataRequest request) {
    final dueAt = request.dueAt;
    if (dueAt == null) {
      return const InfoPill(label: 'SIN SLA');
    }

    final overdue = _isOverdue(request);
    final scheme = Theme.of(context).colorScheme;
    final color = overdue ? scheme.error : scheme.primary;
    final label = overdue
        ? 'Vencida ${DateFormat('d MMM yyyy').format(dueAt)}'
        : 'Límite ${DateFormat('d MMM yyyy').format(dueAt)}';

    return InfoPill(
      label: label,
      backgroundColor: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }

  String _shortUid(String uid) {
    final trimmed = uid.trim();
    if (trimmed.length <= 10) return trimmed;
    return '${trimmed.substring(0, 8)}...';
  }

  Widget _buildRequestsTable(List<DataRequest> requests) {
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
                final isProcessing = _processingRequestIds.contains(request.id);
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
                              _requestTypeLabel(request.type),
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
                    DataCell(Text(_shortUid(request.candidateUid))),
                    DataCell(
                      Text(
                        request.createdAt != null
                            ? DateFormat(
                                'd MMM yyyy',
                              ).format(request.createdAt!)
                            : '-',
                      ),
                    ),
                    DataCell(_buildSlaPill(request)),
                    DataCell(_RequestStatusIndicator(status: request.status)),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _processRequest(request),
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

class _ConsentRecordsTab extends StatelessWidget {
  const _ConsentRecordsTab();

  @override
  Widget build(BuildContext context) {
    final screen = context
        .findAncestorStateOfType<_ConsentManagementScreenState>();
    if (screen == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('consentRecords')
          .where('companyId', isEqualTo: screen.widget.companyId)
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
                              Text(
                                record.candidateUid.length > 8
                                    ? record.candidateUid.substring(0, 8)
                                    : record.candidateUid,
                              ),
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
                              _ConsentStatusIndicator(
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
    );
  }
}

class _DataRequestsTab extends StatelessWidget {
  const _DataRequestsTab();

  @override
  Widget build(BuildContext context) {
    final screen = context
        .findAncestorStateOfType<_ConsentManagementScreenState>();
    if (screen == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dataRequests')
          .where('companyId', isEqualTo: screen.widget.companyId)
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
                .map((d) => DataRequest.fromJson(d.data(), id: d.id))
                .toList(growable: false) ??
            const <DataRequest>[];

        if (requests.isEmpty) {
          return const StateMessage(
            title: 'Sin solicitudes',
            message: 'No hay solicitudes ARSULIPO/AI Act para esta empresa.',
          );
        }

        final overdueCount = requests.where(screen._isOverdue).length;

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
              Expanded(child: screen._buildRequestsTable(requests)),
            ],
          ),
        );
      },
    );
  }
}

class _SalaryBenchmarksTab extends StatefulWidget {
  const _SalaryBenchmarksTab({
    required this.companyId,
    required this.canManage,
  });

  final String companyId;
  final bool canManage;

  @override
  State<_SalaryBenchmarksTab> createState() => _SalaryBenchmarksTabState();
}

class _SalaryBenchmarksTabState extends State<_SalaryBenchmarksTab> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _maleAvgController = TextEditingController();
  final TextEditingController _femaleAvgController = TextEditingController();
  final TextEditingController _nonBinaryAvgController = TextEditingController();
  final TextEditingController _sampleSizeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _roleController.dispose();
    _maleAvgController.dispose();
    _femaleAvgController.dispose();
    _nonBinaryAvgController.dispose();
    _sampleSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('salaryBenchmarks')
          .where('companyId', isEqualTo: widget.companyId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const StateMessage(
            title: 'Error',
            message: 'No se pudieron cargar los benchmarks salariales.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records =
            snapshot.data?.docs
                .map((doc) => _SalaryBenchmarkRecord.fromDoc(doc))
                .toList(growable: false) ??
            const <_SalaryBenchmarkRecord>[];
        final sortedRecords = [...records]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Padding(
          padding: const EdgeInsets.all(uiSpacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Benchmarks Salariales',
                subtitle:
                    'Carga medias por género para auditoría de brecha salarial.',
                titleFontSize: 22,
              ),
              const SizedBox(height: uiSpacing16),
              if (!widget.canManage)
                AppCard(
                  child: Text(
                    'Solo company owner o recruiters con rol admin/recruiter '
                    'pueden actualizar benchmarks salariales.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                _buildFormCard(context),
              const SizedBox(height: uiSpacing16),
              Expanded(
                child: sortedRecords.isEmpty
                    ? const StateMessage(
                        title: 'Sin benchmarks',
                        message:
                            'No hay benchmarks salariales registrados para esta empresa.',
                      )
                    : _buildBenchmarksTable(context, sortedRecords),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actualizar benchmark',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: uiSpacing12),
          TextField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Rol o título',
              hintText: 'Ejemplo: Frontend Engineer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: uiSpacing12),
          Wrap(
            spacing: uiSpacing12,
            runSpacing: uiSpacing12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _maleAvgController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Media hombres (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _femaleAvgController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Media mujeres (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _nonBinaryAvgController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Media no binario (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _sampleSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño muestra',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitBenchmark,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar benchmark'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarksTable(
    BuildContext context,
    List<_SalaryBenchmarkRecord> records,
  ) {
    final salaryFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: 'EUR ',
      decimalDigits: 0,
    );
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Rol')),
            DataColumn(label: Text('Género')),
            DataColumn(label: Text('Media')),
            DataColumn(label: Text('Muestra')),
            DataColumn(label: Text('Actualizado')),
            DataColumn(label: Text('Fuente')),
          ],
          rows: records
              .map(
                (record) => DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          record.roleLabel.isEmpty
                              ? record.roleKey
                              : record.roleLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_genderLabel(record.gender))),
                    DataCell(Text(salaryFormat.format(record.averageSalary))),
                    DataCell(Text(record.sampleSize.toString())),
                    DataCell(
                      Text(
                        DateFormat(
                          'd MMM yyyy, HH:mm',
                        ).format(record.updatedAt),
                      ),
                    ),
                    DataCell(Text(record.source)),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _submitBenchmark() async {
    final role = _roleController.text.trim();
    final maleAvg = _parseOptionalDouble(_maleAvgController.text);
    final femaleAvg = _parseOptionalDouble(_femaleAvgController.text);
    final nonBinaryAvg = _parseOptionalDouble(_nonBinaryAvgController.text);
    final sampleSize = _parseOptionalInt(_sampleSizeController.text) ?? 0;

    if (role.isEmpty) {
      _showMessage('Debes indicar el rol o título.');
      return;
    }
    if (maleAvg == null && femaleAvg == null && nonBinaryAvg == null) {
      _showMessage('Debes completar al menos una media salarial.');
      return;
    }
    if ((maleAvg != null && maleAvg < 0) ||
        (femaleAvg != null && femaleAvg < 0) ||
        (nonBinaryAvg != null && nonBinaryAvg < 0)) {
      _showMessage('Las medias salariales no pueden ser negativas.');
      return;
    }
    if (sampleSize < 0) {
      _showMessage('El tamaño de muestra no puede ser negativo.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<SalaryBenchmarkRepository>().upsertSalaryBenchmark(
        companyId: widget.companyId,
        roleKeyOrTitle: role,
        maleAverageSalary: maleAvg,
        femaleAverageSalary: femaleAvg,
        nonBinaryAverageSalary: nonBinaryAvg,
        sampleSize: sampleSize,
      );

      if (!mounted) return;
      _showMessage('Benchmark actualizado correctamente.');
      _maleAvgController.clear();
      _femaleAvgController.clear();
      _nonBinaryAvgController.clear();
      _sampleSizeController.clear();
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.message?.trim();
      _showMessage(
        message == null || message.isEmpty
            ? 'No se pudo actualizar el benchmark.'
            : message,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo actualizar el benchmark.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  double? _parseOptionalDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _parseOptionalInt(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  String _genderLabel(String gender) {
    return switch (gender) {
      'male' => 'Hombre',
      'female' => 'Mujer',
      'non_binary' => 'No binario',
      _ => gender,
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SalaryBenchmarkRecord {
  const _SalaryBenchmarkRecord({
    required this.roleKey,
    required this.roleLabel,
    required this.gender,
    required this.averageSalary,
    required this.sampleSize,
    required this.source,
    required this.updatedAt,
  });

  final String roleKey;
  final String roleLabel;
  final String gender;
  final double averageSalary;
  final int sampleSize;
  final String source;
  final DateTime updatedAt;

  factory _SalaryBenchmarkRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _SalaryBenchmarkRecord(
      roleKey: _asString(data['roleKey']),
      roleLabel: _asString(data['roleLabel']),
      gender: _asString(data['gender']),
      averageSalary: _asDouble(data['averageSalary']) ?? 0,
      sampleSize: _asInt(data['sampleSize']) ?? 0,
      source: _asString(data['source'], fallback: '-'),
      updatedAt:
          _asDateTime(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _ProcessRequestDialog extends StatefulWidget {
  const _ProcessRequestDialog({required this.request});

  final DataRequest request;

  @override
  State<_ProcessRequestDialog> createState() => _ProcessRequestDialogState();
}

class _ProcessRequestDialogState extends State<_ProcessRequestDialog> {
  late DataRequestStatus _status;
  late TextEditingController _responseController;

  @override
  void initState() {
    super.initState();
    _status = widget.request.status;
    _responseController = TextEditingController(
      text: widget.request.response ?? '',
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  bool get _requiresResponse {
    final isSalaryComparison =
        widget.request.type == DataRequestType.salaryComparison;
    return (isSalaryComparison && _status == DataRequestStatus.completed) ||
        _status == DataRequestStatus.denied;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Procesar solicitud'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${widget.request.type.name}'),
            const SizedBox(height: uiSpacing8),
            Text(widget.request.description),
            const SizedBox(height: uiSpacing12),
            DropdownButtonFormField<DataRequestStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Nuevo estado',
                border: OutlineInputBorder(),
              ),
              items: DataRequestStatus.values
                  .map(
                    (status) => DropdownMenuItem<DataRequestStatus>(
                      value: status,
                      child: Text(status.name.toUpperCase()),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _requiresResponse
                    ? 'Respuesta (obligatoria)'
                    : 'Respuesta (opcional)',
                helperText:
                    widget.request.type == DataRequestType.salaryComparison
                    ? 'Para comparativa salarial completada, se requiere respuesta objetiva.'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final response = _responseController.text.trim();
            if (_requiresResponse && response.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debes indicar una respuesta para continuar.'),
                ),
              );
              return;
            }
            Navigator.of(context).pop(
              _RequestDecision(
                status: _status,
                response: response.isEmpty ? null : response,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _RequestDecision {
  const _RequestDecision({required this.status, required this.response});

  final DataRequestStatus status;
  final String? response;
}

class _ConsentStatusIndicator extends StatelessWidget {
  const _ConsentStatusIndicator({required this.granted});

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

class _RequestStatusIndicator extends StatelessWidget {
  const _RequestStatusIndicator({required this.status});

  final DataRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color = scheme.outline;

    if (status == DataRequestStatus.processing) color = scheme.primary;
    if (status == DataRequestStatus.completed) color = scheme.tertiary;
    if (status == DataRequestStatus.denied) color = scheme.error;

    return InfoPill(
      label: status.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}
