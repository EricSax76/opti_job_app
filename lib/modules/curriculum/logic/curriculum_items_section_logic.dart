import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/models/curriculum_items_section_view_model.dart';

class CurriculumItemsSectionLogic {
  const CurriculumItemsSectionLogic._();

  static CurriculumItemsSectionViewModel buildViewModel(
    List<CurriculumItem> items,
  ) {
    return CurriculumItemsSectionViewModel(
      statusLabel: items.isEmpty ? 'Pendiente' : '${items.length} elementos',
      entries: List<CurriculumItemsSectionEntryViewModel>.generate(
        items.length,
        (index) => _buildEntry(index, items[index]),
        growable: false,
      ),
    );
  }

  static CurriculumItemsSectionEntryViewModel _buildEntry(
    int index,
    CurriculumItem item,
  ) {
    return CurriculumItemsSectionEntryViewModel(
      index: index,
      title: item.title.isEmpty ? 'Sin título' : item.title,
      subtitle: _buildSubtitle(item),
    );
  }

  static String _buildSubtitle(CurriculumItem item) {
    return [
      if (item.subtitle.trim().isNotEmpty) item.subtitle.trim(),
      if (item.period.trim().isNotEmpty) item.period.trim(),
    ].join(' · ');
  }
}
