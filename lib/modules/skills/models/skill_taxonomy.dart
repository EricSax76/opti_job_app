class SkillTaxonomy {
  const SkillTaxonomy({
    required this.id,
    required this.name,
    required this.category,
    this.aliases = const [],
    this.relatedSkills = const [],
    this.popularity = 0,
  });

  final String id;
  final String name;
  final SkillCategory category;
  final List<String> aliases;
  final List<String> relatedSkills;
  final int popularity;

  factory SkillTaxonomy.fromJson(Map<String, dynamic> json) {
    return SkillTaxonomy(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: SkillCategory.fromString(json['category'] as String? ?? 'technical'),
      aliases: (json['aliases'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      relatedSkills: (json['relatedSkills'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      popularity: json['popularity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'aliases': aliases,
      'relatedSkills': relatedSkills,
      'popularity': popularity,
    };
  }
}

enum SkillCategory {
  technical,
  soft,
  tool,
  language,
  certification;

  static SkillCategory fromString(String category) {
    return SkillCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => SkillCategory.technical,
    );
  }
}
