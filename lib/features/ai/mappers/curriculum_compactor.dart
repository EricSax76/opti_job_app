import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumCompactor {
  const CurriculumCompactor();

  Map<String, dynamic> compact(Curriculum curriculum) {
    final trimmedSkills = curriculum.skills
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final uniqueSkills = <String>[];
    for (final skill in trimmedSkills) {
      final alreadyAdded = uniqueSkills.any(
        (value) => value.toLowerCase() == skill.toLowerCase(),
      );
      if (!alreadyAdded) uniqueSkills.add(skill);
      if (uniqueSkills.length >= 25) break;
    }

    List<Map<String, dynamic>> takeLastItems(List<dynamic> items, int max) {
      final start = items.length > max ? items.length - max : 0;
      return items.sublist(start).whereType<Map<String, dynamic>>().map((item) {
        String s(dynamic v, int limit) {
          final text = v is String ? v.trim() : '';
          return text.length <= limit ? text : text.substring(0, limit);
        }

        return <String, dynamic>{
          'title': s(item['title'], 80),
          'subtitle': s(item['subtitle'], 80),
          'period': s(item['period'], 40),
          'description': s(item['description'], 600),
        };
      }).toList();
    }

    final raw = curriculum.toJson();
    final experiences = (raw['experiences'] as List<dynamic>? ?? const []);
    final education = (raw['education'] as List<dynamic>? ?? const []);

    String truncate(String value, int max) =>
        value.length <= max ? value : value.substring(0, max);

    return <String, dynamic>{
      'headline': truncate(curriculum.headline.trim(), 120),
      'summary': truncate(curriculum.summary.trim(), 900),
      'skills': uniqueSkills,
      'experiences': takeLastItems(experiences, 3),
      'education': takeLastItems(education, 3),
      if (curriculum.updatedAt != null)
        'updated_at': curriculum.updatedAt!.toIso8601String(),
    };
  }
}
