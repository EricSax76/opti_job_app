import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/cover_letter/services/cover_letter_service.dart';

void main() {
  group('CoverLetterService.fetchCoverLetterText', () {
    test('returns null when candidate document does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final service = CoverLetterService(firestore: firestore);

      final result = await service.fetchCoverLetterText('candidate-1');

      expect(result, isNull);
    });

    test('returns trimmed text when cover letter is present', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({
        'cover_letter': {'text': '  Carta final  '},
      });
      final service = CoverLetterService(firestore: firestore);

      final result = await service.fetchCoverLetterText('candidate-1');

      expect(result, 'Carta final');
    });

    test('returns null when text is blank', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({
        'cover_letter': {'text': '   '},
      });
      final service = CoverLetterService(firestore: firestore);

      final result = await service.fetchCoverLetterText('candidate-1');

      expect(result, isNull);
    });
  });

  group('CoverLetterService.saveCoverLetterText', () {
    test('persists cover letter text and timestamps', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({});
      final service = CoverLetterService(firestore: firestore);

      await service.saveCoverLetterText(
        candidateUid: 'candidate-1',
        text: 'Mi carta',
      );

      final snapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['updated_at'], isNotNull);
      final coverLetter = data['cover_letter'] as Map<String, dynamic>?;
      expect(coverLetter, isNotNull);
      expect(coverLetter!['text'], 'Mi carta');
      expect(coverLetter['updated_at'], isNotNull);
    });
  });
}
