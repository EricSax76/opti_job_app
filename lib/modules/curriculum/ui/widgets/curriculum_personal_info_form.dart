import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_actions.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil Profesional',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: uiInk,
          ),
        ),
        const SizedBox(height: uiSpacing16),
        TextFormField(
          controller: formCubit.headlineController,
          decoration: const InputDecoration(
            labelText: 'Titular profesional',
            hintText: 'Ej: Senior Fullstack Developer',
          ),
        ),
        const SizedBox(height: uiSpacing16),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            TextFormField(
              controller: formCubit.summaryController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Resumen / Perfil',
                alignLabelWithHint: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(uiSpacing8),
              child: TextButton.icon(
                onPressed: widget.state.isSaving || _isImprovingSummary
                    ? null
                    : () async {
                        setState(() => _isImprovingSummary = true);
                        try {
                          final result = await CurriculumLogic.improveSummary(
                            context: context,
                            state: widget.state,
                          );
                          if (!context.mounted) return;
                          
                          if (result is ActionFailure) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text((result as ActionFailure).message)),
                             );
                          } else if (result is ActionSuccess<String>) {
                             final suggestion = result.data;
                             if (suggestion != null) {
                                final shouldApply = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Resumen sugerido'),
                                      content: SingleChildScrollView(child: SelectableText(suggestion)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Aplicar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (shouldApply == true && context.mounted) {
                                  context.read<CurriculumFormCubit>().summaryController.text = suggestion;
                                }
                             }
                          }
                        } finally {
                          if (mounted) setState(() => _isImprovingSummary = false);
                        }
                    },
                style: TextButton.styleFrom(
                  backgroundColor: uiAccentSoft,
                  padding: const EdgeInsets.symmetric(horizontal: uiSpacing12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(uiPillRadius),
                  ),
                ),
                icon: _isImprovingSummary
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  _isImprovingSummary ? 'Mejorando...' : 'Mejorar con IA',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: uiSpacing16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: formCubit.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(width: uiSpacing16),
            Expanded(
              child: TextFormField(
                controller: formCubit.locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: Icon(Icons.place_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

