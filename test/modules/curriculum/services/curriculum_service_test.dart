import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/services/curriculum_service.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  group('CurriculumService.fetchCurriculum', () {
    test('bootstraps empty main curriculum document when missing', () async {
      final firestore = FakeFirebaseFirestore();
      final storage = _MockFirebaseStorage();
      final service = CurriculumService(firestore: firestore, storage: storage);

      final curriculum = await service.fetchCurriculum('candidate-1');

      expect(curriculum.headline, isEmpty);
      expect(curriculum.summary, isEmpty);
      expect(curriculum.phone, isEmpty);
      expect(curriculum.location, isEmpty);
      expect(curriculum.skills, isEmpty);
      expect(curriculum.experiences, isEmpty);
      expect(curriculum.education, isEmpty);
      expect(curriculum.updatedAt, isNotNull);

      final snapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .collection('curriculum')
          .doc('main')
          .get();
      final data = snapshot.data();

      expect(snapshot.exists, isTrue);
      expect(data, isNotNull);
      expect(data!['headline'], '');
      expect(data['summary'], '');
      expect(data['skills'], isA<List<dynamic>>());
      expect(data['updated_at'], isNotNull);
    });
  });

  group('CurriculumService.saveCurriculum', () {
    test('persists curriculum fields and updated timestamp', () async {
      final firestore = FakeFirebaseFirestore();
      final storage = _MockFirebaseStorage();
      final service = CurriculumService(firestore: firestore, storage: storage);

      await service.saveCurriculum(
        candidateUid: 'candidate-1',
        curriculum: const Curriculum(
          headline: 'Flutter Developer',
          summary: 'Resumen',
          phone: '+34 600000000',
          location: 'Madrid',
          skills: ['Flutter', 'Dart'],
          experiences: [
            CurriculumItem(
              title: 'Mobile Dev',
              subtitle: 'Acme',
              period: '2022-2025',
              description: 'Desarrollo de apps',
            ),
          ],
          education: [
            CurriculumItem(
              title: 'Ingenieria',
              subtitle: 'UPM',
              period: '2016-2020',
              description: 'Grado',
            ),
          ],
        ),
      );

      final snapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .collection('curriculum')
          .doc('main')
          .get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['headline'], 'Flutter Developer');
      expect(data['summary'], 'Resumen');
      expect(data['phone'], '+34 600000000');
      expect(data['location'], 'Madrid');
      expect(data['skills'], ['Flutter', 'Dart']);
      expect(data['experiences'], isNotEmpty);
      expect(data['education'], isNotEmpty);
      expect(data['updated_at'], isNotNull);
    });
  });
}
