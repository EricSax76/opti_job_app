import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_section_header.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

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
          subtitle: 'Agrega palabras clave',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: cvInputDecoration(labelText: 'Nueva habilidad'),
                onSubmitted: (value) {
                  formCubit.addSkill(value);
                  _skillController.clear();
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cvInk,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                formCubit.addSkill(_skillController.text);
                _skillController.clear();
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in widget.skills)
              InputChip(
                label: Text(skill),
                onDeleted: () => formCubit.removeSkill(skill),
              ),
          ],
        ),
      ],
    );
  }
}
