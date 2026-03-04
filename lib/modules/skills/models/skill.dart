class Skill {
  const Skill({
    required this.skillId,
    required this.name,
    required this.level,
    required this.yearsOfExperience,
  });

  final String skillId;
  final String name;
  final SkillLevel level;
  final double yearsOfExperience;

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      skillId: json['skillId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      level: SkillLevel.fromString(json['level'] as String? ?? 'beginner'),
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'name': name,
      'level': level.name,
      'yearsOfExperience': yearsOfExperience,
    };
  }
}

enum SkillLevel {
  beginner,
  intermediate,
  advanced,
  expert;

  static SkillLevel fromString(String level) {
    return SkillLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => SkillLevel.beginner,
    );
  }
}
