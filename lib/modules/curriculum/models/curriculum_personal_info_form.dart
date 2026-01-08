import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_logic.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

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
          decoration: cvInputDecoration(labelText: 'Titular'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: formCubit.summaryController,
          maxLines: 4,
          decoration: cvInputDecoration(labelText: 'Resumen'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Spacer(),
            OutlinedButton.icon(
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _isImprovingSummary ? 'Generando...' : 'Mejorar con IA',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: formCubit.phoneController,
                decoration: cvInputDecoration(labelText: 'Teléfono'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: formCubit.locationController,
                decoration: cvInputDecoration(labelText: 'Ubicación'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
