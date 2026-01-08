import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class GenerateOfferDialog extends StatefulWidget {
  const GenerateOfferDialog({
    super.key,
    required this.companyName,
    required this.initialRole,
    required this.initialLocation,
    required this.initialJobType,
    required this.initialSalaryMin,
    required this.initialSalaryMax,
    required this.initialEducation,
    required this.initialKeyIndicators,
  });

  final String companyName;
  final String initialRole;
  final String initialLocation;
  final String initialJobType;
  final String initialSalaryMin;
  final String initialSalaryMax;
  final String initialEducation;
  final String initialKeyIndicators;

  @override
  State<GenerateOfferDialog> createState() => _GenerateOfferDialogState();
}

class _GenerateOfferDialogState extends State<GenerateOfferDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _role;
  late final TextEditingController _location;
  late final TextEditingController _jobType;
  late final TextEditingController _salaryMin;
  late final TextEditingController _salaryMax;
  late final TextEditingController _education;
  late final TextEditingController _keyIndicators;

  @override
  void initState() {
    super.initState();
    _role = TextEditingController(text: widget.initialRole);
    _location = TextEditingController(text: widget.initialLocation);
    _jobType = TextEditingController(text: widget.initialJobType);
    _salaryMin = TextEditingController(text: widget.initialSalaryMin);
    _salaryMax = TextEditingController(text: widget.initialSalaryMax);
    _education = TextEditingController(text: widget.initialEducation);
    _keyIndicators = TextEditingController(text: widget.initialKeyIndicators);
  }

  @override
  void dispose() {
    _role.dispose();
    _location.dispose();
    _jobType.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _education.dispose();
    _keyIndicators.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generar oferta con IA'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _role,
                decoration: _inputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _location,
                decoration: _inputDecoration(labelText: 'Ubicación'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ubicación es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _jobType,
                decoration: _inputDecoration(labelText: 'Tipología'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMin,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(labelText: 'Salario mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMax,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(labelText: 'Salario máximo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _education,
                decoration: _inputDecoration(labelText: 'Educación requerida'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _keyIndicators,
                maxLines: 2,
                decoration: _inputDecoration(labelText: 'Indicadores clave'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final payload = <String, dynamic>{
              'companyName': widget.companyName,
              'role': _role.text.trim(),
              'location': _location.text.trim(),
              'jobType': _jobType.text.trim(),
              'salaryMin': _salaryMin.text.trim(),
              'salaryMax': _salaryMax.text.trim(),
              'education': _education.text.trim(),
              'keyIndicators': _keyIndicators.text.trim(),
            };

            Navigator.of(context).pop(payload);
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: uiBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(uiFieldRadius),
        borderSide: const BorderSide(color: uiBorder),
      ),
    );
  }
}
