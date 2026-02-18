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
      await firestore.collection('candidates').doc('candidate-1').set({});
      await firestore
          .collection('candidates')
          .doc('candidate-1')
          .collection('cover_letter')
          .doc('main')
          .set({'text': '  Carta final  '});
      final service = CoverLetterService(firestore: firestore);

      final result = await service.fetchCoverLetterText('candidate-1');

      expect(result, 'Carta final');
    });

    test('returns null when text is blank', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({});
      await firestore
          .collection('candidates')
          .doc('candidate-1')
          .collection('cover_letter')
          .doc('main')
          .set({'text': '   '});
      final service = CoverLetterService(firestore: firestore);

      final result = await service.fetchCoverLetterText('candidate-1');

      expect(result, isNull);
    });

    test(
      'falls back to legacy cover_letter field in candidate document',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('candidates').doc('candidate-1').set({
          'cover_letter': {'text': '  Carta legacy  '},
        });
        final service = CoverLetterService(firestore: firestore);

        final result = await service.fetchCoverLetterText('candidate-1');

        expect(result, 'Carta legacy');
      },
    );
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

      final coverLetterSnapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .collection('cover_letter')
          .doc('main')
          .get();
      final data = coverLetterSnapshot.data();

      expect(data, isNotNull);
      expect(data!['updated_at'], isNotNull);
      expect(data['text'], 'Mi carta');

      final candidateSnapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .get();
      final candidateData = candidateSnapshot.data();
      expect(candidateData, isNotNull);
      expect(candidateData!['cover_letter'], isNull);
    });
  });
}
