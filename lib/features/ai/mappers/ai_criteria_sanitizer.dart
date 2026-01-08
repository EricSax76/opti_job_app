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
      if (s(criteria['role'], 80) case final v?) 'role': v,
      if (s(criteria['seniority'], 40) case final v?) 'seniority': v,
      if (s(criteria['companyName'], 80) case final v?) 'companyName': v,
      if (s(criteria['location'], 80) case final v?) 'location': v,
      if (s(criteria['jobType'], 40) case final v?) 'jobType': v,
      if (s(criteria['salaryMin'], 20) case final v?) 'salaryMin': v,
      if (s(criteria['salaryMax'], 20) case final v?) 'salaryMax': v,
      if (s(criteria['education'], 80) case final v?) 'education': v,
      if (s(criteria['tone'], 40) case final v?) 'tone': v,
      if (s(criteria['language'], 20) case final v?) 'language': v,
      if (s(criteria['about'], 600) case final v?) 'about': v,
      if (s(criteria['responsibilities'], 900) case final v?)
        'responsibilities': v,
      if (s(criteria['requirements'], 900) case final v?) 'requirements': v,
      if (s(criteria['benefits'], 600) case final v?) 'benefits': v,
      if (s(criteria['notes'], 400) case final v?) 'notes': v,
      'mustHaveSkills': list(criteria['mustHaveSkills'], 12, 40),
      'niceToHaveSkills': list(criteria['niceToHaveSkills'], 12, 40),
    };
  }
}
