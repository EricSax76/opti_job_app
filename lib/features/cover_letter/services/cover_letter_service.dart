import 'package:cloud_firestore/cloud_firestore.dart';

class CoverLetterService {
  CoverLetterService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> fetchCoverLetterText(String candidateUid) async {
    final doc = await _firestore
        .collection('candidates')
        .doc(candidateUid)
        .get();
    final data = doc.data();
    final coverLetter = data?['cover_letter'];
    final rawText = coverLetter is Map ? coverLetter['text'] : null;
    final text = rawText is String ? rawText.trim() : null;
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  Future<void> saveCoverLetterText({
    required String candidateUid,
    required String text,
  }) async {
    await _firestore.collection('candidates').doc(candidateUid).update({
      'cover_letter': {
        'text': text,
        'updated_at': FieldValue.serverTimestamp(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
