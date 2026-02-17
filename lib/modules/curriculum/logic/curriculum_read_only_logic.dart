import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/models/curriculum_read_only_view_model.dart';

class CurriculumReadOnlyLogic {
  const CurriculumReadOnlyLogic._();

  static CurriculumReadOnlyViewModel buildViewModel(Curriculum curriculum) {
    final headline = curriculum.headline.trim();
    final summary = curriculum.summary.trim();
    final phone = _normalizeNullableText(curriculum.phone);
    final location = _normalizeNullableText(curriculum.location);
    final skills = curriculum.skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList(growable: false);

    return CurriculumReadOnlyViewModel(
      headline: headline,
      summary: summary,
      contact: CurriculumReadOnlyContactViewModel(
        phone: phone,
        location: location,
      ),
      skills: skills,
      experiences: _mapItems(curriculum.experiences),
      education: _mapItems(curriculum.education),
      attachmentFileName: curriculum.attachment?.fileName,
    );
  }

  static List<CurriculumReadOnlyItemViewModel> _mapItems(
    List<CurriculumItem> items,
  ) {
    return items
        .map(
          (item) => CurriculumReadOnlyItemViewModel(
            title: _normalizeText(item.title),
            subtitle: _normalizeNullableText(item.subtitle),
            period: _normalizeNullableText(item.period),
            description: _normalizeNullableText(item.description),
          ),
        )
        .toList(growable: false);
  }

  static String _normalizeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Sin título';
  }

  static String? _normalizeNullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
