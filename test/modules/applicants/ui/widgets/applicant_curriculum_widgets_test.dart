import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_content.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_header.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

void main() {
  group('ApplicantCurriculumHeader', () {
    testWidgets('renders candidate info correctly', (tester) async {
      const candidate = Candidate(
        id: 1,
        name: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        uid: 'uid123',
        role: 'candidate',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantCurriculumHeader(
              candidate: candidate,
              hasCurriculum: true,
              isExporting: false,
              isMatching: false,
              onExport: () {},
              onMatch: () {},
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsOneWidget);
      expect(find.text('Match IA'), findsOneWidget);
    });

    testWidgets('disables buttons when exporting/matching', (tester) async {
      const candidate = Candidate(
        id: 1,
        name: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        uid: 'uid123',
        role: 'candidate',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantCurriculumHeader(
              candidate: candidate,
              hasCurriculum: true,
              isExporting: true,
              isMatching: true,
              onExport: () {},
              onMatch: () {},
            ),
          ),
        ),
      );

      expect(find.text('Exportando...'), findsOneWidget);
      expect(find.text('Analizando...'), findsOneWidget);
    });
  });

  group('ApplicantCurriculumContent', () {
    testWidgets('renders curriculum and cover letter sections', (tester) async {
      const candidate = Candidate(
        id: 1,
        name: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        uid: 'uid123',
        role: 'candidate',
        coverLetter: CandidateCoverLetter(text: 'Hello world'),
      );
      final curriculum = Curriculum(
        experiences: [],
        education: [],
        skills: [],
        headline: 'Headline',
        summary: 'Summary',
        phone: '123456789',
        location: 'Location',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantCurriculumContent(
              candidate: candidate,
              curriculum: curriculum,
              offerId: 'offer-1',
              hasVideoCurriculum: false,
              canViewVideoCurriculum: false,
              isExporting: false,
              isMatching: false,
              onExport: () {},
              onMatch: () {},
            ),
          ),
        ),
      );

      expect(find.text('Curriculum'), findsOneWidget);
      expect(find.text('Carta de presentación'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });
  });
}
