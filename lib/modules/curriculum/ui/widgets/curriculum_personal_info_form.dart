import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_logic.dart';

class CurriculumPersonalInfoForm extends StatefulWidget {
  const CurriculumPersonalInfoForm({super.key, required this.state});

  final CurriculumFormState state;

  @override
  State<CurriculumPersonalInfoForm> createState() =>
      _CurriculumPersonalInfoFormState();
}

class _CurriculumPersonalInfoFormState
    extends State<CurriculumPersonalInfoForm> {
  var _isImprovingSummary = false;

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<CurriculumFormCubit>();

    return Column(
      children: [
        TextFormField(
          controller: formCubit.headlineController,
          decoration: const InputDecoration(labelText: 'Titular profesional'),
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          controller: formCubit.summaryController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Resumen / Perfil'),
        ),
        const SizedBox(height: uiSpacing8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.state.isSaving || _isImprovingSummary
                ? null
                : () => CurriculumLogic.improveSummary(
                      context: context,
                      state: widget.state,
                      onStart: () => setState(() => _isImprovingSummary = true),
                      onEnd: () => setState(() => _isImprovingSummary = false),
                    ),
            icon: _isImprovingSummary
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined, size: 16),
            label: Text(
              _isImprovingSummary ? 'Generando...' : 'Mejorar con IA',
            ),
          ),
        ),
        const SizedBox(height: uiSpacing12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: formCubit.phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
            ),
            const SizedBox(width: uiSpacing12),
            Expanded(
              child: TextFormField(
                controller: formCubit.locationController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

