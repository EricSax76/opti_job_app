import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_attachment_logic.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_items_section_logic.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_read_only_logic.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

void main() {
  group('CurriculumAttachmentLogic', () {
    test('buildCardViewModel formats bytes and updated date', () {
      final attachment = CurriculumAttachment(
        fileName: 'cv.pdf',
        storagePath: 'curriculum/cv.pdf',
        contentType: 'application/pdf',
        sizeBytes: 1536,
        updatedAt: DateTime.utc(2026, 2, 5),
      );

      final viewModel = CurriculumAttachmentLogic.buildCardViewModel(
        attachment,
      );

      expect(viewModel.fileName, 'cv.pdf');
      expect(viewModel.metadataLabel, '1.5 KB · Actualizado: 05/02/2026');
    });
  });

  group('CurriculumReadOnlyLogic', () {
    test('buildViewModel trims and derives section visibility', () {
      final curriculum = Curriculum(
        headline: '  Senior Flutter Dev  ',
        summary: '  Construyo apps escalables. ',
        phone: '  +34 600 000 000 ',
        location: '  Madrid ',
        skills: const [' Flutter ', ' ', 'Dart'],
        experiences: const [],
        education: const [],
        attachment: const CurriculumAttachment(
          fileName: 'cv.docx',
          storagePath: 'curriculum/cv.docx',
          contentType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          sizeBytes: 2048,
        ),
      );

      final viewModel = CurriculumReadOnlyLogic.buildViewModel(curriculum);

      expect(viewModel.headline, 'Senior Flutter Dev');
      expect(viewModel.summary, 'Construyo apps escalables.');
      expect(viewModel.contact.phone, '+34 600 000 000');
      expect(viewModel.contact.location, 'Madrid');
      expect(viewModel.skills, ['Flutter', 'Dart']);
      expect(viewModel.hasHeadline, isTrue);
      expect(viewModel.hasSummary, isTrue);
      expect(viewModel.hasContactInfo, isTrue);
      expect(viewModel.hasSkills, isTrue);
      expect(viewModel.hasAttachment, isTrue);
      expect(viewModel.attachmentFileName, 'cv.docx');
    });
  });

  group('CurriculumItemsSectionLogic', () {
    test('buildViewModel creates status and section entries', () {
      const items = [
        CurriculumItem(
          title: '',
          subtitle: '  Empresa X ',
          period: ' 2020 - 2024 ',
          description: 'Descripción',
        ),
      ];

      final viewModel = CurriculumItemsSectionLogic.buildViewModel(items);

      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.statusLabel, '1 elementos');
      expect(viewModel.entries, hasLength(1));
      expect(viewModel.entries.first.title, 'Sin título');
      expect(viewModel.entries.first.subtitle, 'Empresa X · 2020 - 2024');
    });
  });
}
