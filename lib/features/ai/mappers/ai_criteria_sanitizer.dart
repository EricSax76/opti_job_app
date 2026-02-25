class AiCriteriaSanitizer {
  const AiCriteriaSanitizer();

  Map<String, dynamic> compact(Map<String, dynamic> criteria) {
    String? s(dynamic value, int max) {
      if (value is! String) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
    }

    List<String> list(dynamic value, int maxItems, int maxLen) {
      if (value is! List) return const [];
      final out = <String>[];
      for (final item in value) {
        if (item is! String) continue;
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;
        out.add(
          trimmed.length <= maxLen ? trimmed : trimmed.substring(0, maxLen),
        );
        if (out.length >= maxItems) break;
      }
      return out;
    }

    return <String, dynamic>{
      'role': ?s(criteria['role'], 80),
      'seniority': ?s(criteria['seniority'], 40),
      'companyName': ?s(criteria['companyName'], 80),
      'location': ?s(criteria['location'], 80),
      'jobType': ?s(criteria['jobType'], 40),
      'salaryMin': ?s(criteria['salaryMin'], 20),
      'salaryMax': ?s(criteria['salaryMax'], 20),
      'education': ?s(criteria['education'], 80),
      'tone': ?s(criteria['tone'], 40),
      'language': ?s(criteria['language'], 20),
      'about': ?s(criteria['about'], 600),
      'responsibilities': ?s(criteria['responsibilities'], 900),
      'requirements': ?s(criteria['requirements'], 900),
      'benefits': ?s(criteria['benefits'], 600),
      'notes': ?s(criteria['notes'], 400),
      'mustHaveSkills': list(criteria['mustHaveSkills'], 12, 40),
      'niceToHaveSkills': list(criteria['niceToHaveSkills'], 12, 40),
    };
  }
}
