import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/skills/models/skill.dart';

class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.skill, this.onDeleted});

  final Skill skill;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill.name),
          const SizedBox(width: 4),
          _ProficiencyBadge(
            level: skill.level,
            color: _getProficiencyColor(context, skill.level),
          ),
          if (skill.yearsOfExperience > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${skill.yearsOfExperience.toStringAsFixed(1)}y',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
      onDeleted: onDeleted,
      backgroundColor: _getProficiencyColor(
        context,
        skill.level,
      ).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getProficiencyColor(
            context,
            skill.level,
          ).withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _getProficiencyColor(BuildContext context, SkillLevel level) {
    final scheme = Theme.of(context).colorScheme;
    switch (level) {
      case SkillLevel.beginner:
        return scheme.primary;
      case SkillLevel.intermediate:
        return scheme.tertiary;
      case SkillLevel.advanced:
        return scheme.secondary;
      case SkillLevel.expert:
        return scheme.error;
    }
  }
}

class _ProficiencyBadge extends StatelessWidget {
  const _ProficiencyBadge({required this.level, required this.color});

  final SkillLevel level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InfoPill(
      label: level.name[0].toUpperCase(),
      backgroundColor: color,
      borderColor: color.withValues(alpha: 0.95),
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}
