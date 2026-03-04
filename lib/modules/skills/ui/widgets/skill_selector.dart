import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/skills/models/skill_taxonomy.dart';
import 'package:opti_job_app/modules/skills/repositories/skills_repository.dart';

class SkillSelector extends StatefulWidget {
  const SkillSelector({
    super.key,
    required this.repository,
    required this.onSkillSelected,
    this.label = 'Search skills...',
  });

  final SkillsRepository repository;
  final ValueChanged<SkillTaxonomy> onSkillSelected;
  final String label;

  @override
  State<SkillSelector> createState() => _SkillSelectorState();
}

class _SkillSelectorState extends State<SkillSelector> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Autocomplete<SkillTaxonomy>(
      displayStringForOption: (option) => option.name,
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<SkillTaxonomy>.empty();
        }
        return await widget.repository.searchSkills(textEditingValue.text);
      },
      onSelected: (option) {
        widget.onSkillSelected(option);
        _controller.clear();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return AppCard(
          padding: EdgeInsets.zero,
          borderRadius: uiFieldRadius,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: uiSpacing12,
                vertical: uiSpacing12,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => controller.clear(),
                    )
                  : null,
            ),
            onSubmitted: (value) => onFieldSubmitted(),
          ),
        );
      },
    );
  }
}
