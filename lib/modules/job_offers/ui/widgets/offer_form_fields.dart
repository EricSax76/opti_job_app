import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/ui/models/job_offer_filter_options.dart';
import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';

class OfferFormFields extends StatelessWidget {
  const OfferFormFields({super.key, required this.controllers});

  final OfferFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controllers.title,
          decoration: _inputDecoration(labelText: 'Título'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: controllers.description,
          maxLines: 4,
          decoration: _inputDecoration(labelText: 'Descripción'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: controllers.location,
          decoration: _inputDecoration(labelText: 'Ubicación'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La ubicación es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: uiSpacing12),
        _OfferDropdownField(
          controller: controllers.jobType,
          label: 'Modalidad',
          items: jobOfferFilterJobTypes,
          isRequired: true,
        ),
        const SizedBox(height: uiSpacing12),
        _OfferDropdownField(
          controller: controllers.jobCategory,
          label: 'Categoría del puesto',
          items: jobOfferFilterJobCategories,
          isRequired: true,
        ),
        const SizedBox(height: uiSpacing12),
        _OfferDropdownField(
          controller: controllers.education,
          label: 'Estudios mínimos',
          items: jobOfferFilterEducationLevels,
          isRequired: true,
        ),
        const SizedBox(height: uiSpacing12),
        _OfferDropdownField(
          controller: controllers.workSchedule,
          label: 'Jornada laboral',
          items: jobOfferFilterWorkSchedules,
          isRequired: true,
        ),
        const SizedBox(height: uiSpacing12),
        _OfferDropdownField(
          controller: controllers.contractType,
          label: 'Tipo de contrato',
          items: jobOfferFilterContractTypes,
          isRequired: true,
        ),
        const SizedBox(height: uiSpacing12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers.salaryMin,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(labelText: 'Salario mínimo'),
                validator: (value) => _validateSalary(
                  value,
                  otherValue: controllers.salaryMax.text,
                ),
              ),
            ),
            const SizedBox(width: uiSpacing12),
            Expanded(
              child: TextFormField(
                controller: controllers.salaryMax,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(labelText: 'Salario máximo'),
                validator: (value) => _validateSalary(
                  value,
                  otherValue: controllers.salaryMin.text,
                  isMax: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: controllers.keyIndicators,
          maxLines: 2,
          decoration: _inputDecoration(labelText: 'Indicadores clave'),
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(labelText: labelText);
  }

  String? _validateSalary(
    String? value, {
    required String otherValue,
    bool isMax = false,
  }) {
    final salary = _parseSalary(value);
    final otherSalary = _parseSalary(otherValue);
    if (salary == null || otherSalary == null) {
      return null;
    }
    if (isMax && salary < otherSalary) {
      return 'El salario máximo no puede ser menor al mínimo';
    }
    if (!isMax && salary > otherSalary) {
      return 'El salario mínimo no puede superar el máximo';
    }
    return null;
  }

  int? _parseSalary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }
}

/// A dropdown form field that syncs its selected value with a
/// [TextEditingController] so that [OfferFormControllers] can read the
/// value uniformly via `.text`.
class _OfferDropdownField extends StatefulWidget {
  const _OfferDropdownField({
    required this.controller,
    required this.label,
    required this.items,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final List<String> items;
  final bool isRequired;

  @override
  State<_OfferDropdownField> createState() => _OfferDropdownFieldState();
}

class _OfferDropdownFieldState extends State<_OfferDropdownField> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.text.trim();
    if (initial.isNotEmpty && widget.items.contains(initial)) {
      _selectedValue = initial;
    }
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final text = widget.controller.text.trim();
    final newValue = text.isNotEmpty && widget.items.contains(text)
        ? text
        : (text.isEmpty ? null : _selectedValue);
    if (newValue != _selectedValue) {
      setState(() => _selectedValue = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: widget.label),
      items: widget.items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedValue = value);
        widget.controller.text = value ?? '';
      },
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '${widget.label} es obligatorio';
              }
              return null;
            }
          : null,
    );
  }
}
