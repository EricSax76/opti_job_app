import 'package:opti_job_app/modules/skills/models/skill.dart';

class SkillsCompactor {
  /// Compacts a list of skills into a concise string format for AI prompts
  /// Format: "SkillName (Level, YearsExp), ..."
  static String compact(List<Skill> skills) {
    if (skills.isEmpty) return 'None';
    return skills.map((s) {
      return '${s.name} (${s.level.name}${s.yearsOfExperience > 0 ? ', ${s.yearsOfExperience}y' : ''})';
    }).join(', ');
  }

  /// Compacts job offer skills
  static String compactJobSkills({
    required List<dynamic> required,
    required List<dynamic> preferred,
  }) {
    final reqStr = required.isNotEmpty 
        ? 'Required: ${required.map((s) => s.name).join(', ')}' 
        : 'Required: None';
    final prefStr = preferred.isNotEmpty 
        ? 'Preferred: ${preferred.map((s) => s.name).join(', ')}' 
        : 'Preferred: None';
    return '$reqStr | $prefStr';
  }
}
