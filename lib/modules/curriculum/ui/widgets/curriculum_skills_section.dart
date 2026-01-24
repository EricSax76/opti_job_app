import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_section_header.dart';

class CurriculumSkillsSection extends StatefulWidget {
  const CurriculumSkillsSection({super.key, required this.skills});

  final List<String> skills;

  @override
  State<CurriculumSkillsSection> createState() =>
      _CurriculumSkillsSectionState();
}

class _CurriculumSkillsSectionState extends State<CurriculumSkillsSection> {
  final _skillController = TextEditingController();

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<CurriculumFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CurriculumSectionHeader(
          title: 'Habilidades',
          subtitle: 'Agrega palabras clave sobre tus conocimientos',
        ),
        const SizedBox(height: uiSpacing16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillController,
                decoration: const InputDecoration(
                  labelText: 'Nueva habilidad',
                  hintText: 'Ej: Flutter, Python, SQL',
                ),
                onFieldSubmitted: (value) {
                  formCubit.addSkill(value);
                  _skillController.clear();
                },
              ),
            ),
            const SizedBox(width: uiSpacing8),
            IconButton.filled(
              onPressed: () {
                formCubit.addSkill(_skillController.text);
                _skillController.clear();
              },
              icon: const Icon(Icons.add),
              tooltip: 'Agregar habilidad',
            ),
          ],
        ),
        if (widget.skills.isNotEmpty) ...[
          const SizedBox(height: uiSpacing20),
          Wrap(
            spacing: uiSpacing8,
            runSpacing: uiSpacing8,
            children: [
              for (final skill in widget.skills)
                InputChip(
                  label: Text(skill),
                  onDeleted: () => formCubit.removeSkill(skill),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  padding: const EdgeInsets.all(uiSpacing4),
                  backgroundColor: uiAccentSoft,
                  labelStyle: const TextStyle(
                    color: uiInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

