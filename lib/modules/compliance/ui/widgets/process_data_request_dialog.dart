import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

typedef RequestDecision = ({DataRequestStatus status, String? response});

class ProcessDataRequestDialog extends StatefulWidget {
  const ProcessDataRequestDialog({super.key, required this.request});

  final DataRequest request;

  @override
  State<ProcessDataRequestDialog> createState() =>
      _ProcessDataRequestDialogState();
}

class _ProcessDataRequestDialogState extends State<ProcessDataRequestDialog> {
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
            Navigator.of(context).pop((
              status: _status,
              response: response.isEmpty ? null : response,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
