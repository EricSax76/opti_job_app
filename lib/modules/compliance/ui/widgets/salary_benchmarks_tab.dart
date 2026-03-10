import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

class SalaryBenchmarksTab extends StatefulWidget {
  const SalaryBenchmarksTab({
    super.key,
    required this.companyId,
    required this.canManage,
  });

  final String companyId;
  final bool canManage;

  @override
  State<SalaryBenchmarksTab> createState() => _SalaryBenchmarksTabState();
}

class _SalaryBenchmarksTabState extends State<SalaryBenchmarksTab> {
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
                .map((doc) => SalaryBenchmarkRecord.fromDoc(doc))
                .toList(growable: false) ??
            const <SalaryBenchmarkRecord>[];
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
              _numericField(
                controller: _maleAvgController,
                label: 'Media hombres (€)',
              ),
              _numericField(
                controller: _femaleAvgController,
                label: 'Media mujeres (€)',
              ),
              _numericField(
                controller: _nonBinaryAvgController,
                label: 'Media no binario (€)',
              ),
              _numericField(
                controller: _sampleSizeController,
                label: 'Tamaño muestra',
                allowDecimals: false,
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
    List<SalaryBenchmarkRecord> records,
  ) {
    final salaryFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: 'EUR ',
      decimalDigits: 0,
    );
    final updatedAtFormat = DateFormat('d MMM yyyy, HH:mm');

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
                    DataCell(Text(salaryGenderLabel(record.gender))),
                    DataCell(Text(salaryFormat.format(record.averageSalary))),
                    DataCell(Text(record.sampleSize.toString())),
                    DataCell(Text(updatedAtFormat.format(record.updatedAt))),
                    DataCell(Text(record.source)),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    bool allowDecimals = true,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        keyboardType: allowDecimals
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
