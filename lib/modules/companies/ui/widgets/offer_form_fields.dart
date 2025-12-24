import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:opti_job_app/modules/companies/ui/widgets/offer_form_controllers.dart';

class OfferFormFields extends StatelessWidget {
  const OfferFormFields({super.key, required this.controllers});

  final OfferFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controllers.title,
          decoration: const InputDecoration(
            labelText: 'Título',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El título es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.description,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Descripción',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La descripción es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.location,
          decoration: const InputDecoration(
            labelText: 'Ubicación',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La ubicación es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.jobType,
          decoration: const InputDecoration(
            labelText: 'Tipología',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers.salaryMin,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Salario mínimo',
                ),
                validator: (value) => _validateSalary(
                  value,
                  otherValue: controllers.salaryMax.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controllers.salaryMax,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Salario máximo',
                ),
                validator: (value) => _validateSalary(
                  value,
                  otherValue: controllers.salaryMin.text,
                  isMax: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controllers.education,
          decoration: const InputDecoration(
            labelText: 'Educación requerida',
          ),
        ),
      ],
    );
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
